//SPDX-License-Identifier: Unlicensed
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../interface/IGalleryFactory.sol';
import './Gallery.sol';
import '../interface/IGallery.sol';
import '../interface/INFT.sol';
import '../interface/IMarketPlace.sol';

pragma solidity 0.8.10;

contract GalleryFactory is ReentrancyGuard, IGalleryFactory, Multicall, Ownable {
	using Counters for Counters.Counter;
	using EnumerableSet for EnumerableSet.Bytes32Set;

	///@notice stores the gallery info in a struct
	struct galleryInfo {
		address owner;
		address galleryAddress;
		string name;
		IGallery gallery;
	}
	///@dev instance of NFT contract
	INFT public NFT;

	///@dev instance of marketplace contract
	IMarketPlace public marketPlace;

	// IMarketPlace public market_dollar;

	///@notice blockNumber when contract is deployed
	///@dev provides blockNumber when contract is deployed
	uint256 public blockNumber;

	///@notice provides information of the particular gallery
	///@dev maps the bytes32 hash of gallery name with galleryInfo struct
	mapping(bytes32 => galleryInfo) public galleries;

	EnumerableSet.Bytes32Set private allgalleriesId;

	constructor(
		address nft,
		address market // address _dollarmarket
	) checkAddress(nft) checkAddress(market) {
		NFT = INFT(nft);
		marketPlace = IMarketPlace(market);
		// market_dollar = IMarketPlace(_dollarmarket);

		blockNumber = block.number;
	}

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	///@notice create new gallery
	///@param _id unique id  of the gallery
	///@param _owner address of the gallery owner
	function createGallery(string calldata _id, address _owner) public override nonReentrant {
		bytes32 galleryid = findHash(_id);
		require(!allgalleriesId.contains(galleryid), 'Id already registered');
		allgalleriesId.add(galleryid);
		// Gallery galleryaddress = new Gallery(_name, _owner, address(NFT), address(marketPlace), address(market_dollar));
		Gallery galleryaddress = new Gallery(_id, _owner, address(NFT), address(marketPlace));

		galleries[galleryid] = galleryInfo(_owner, address(galleryaddress), _id, IGallery(address(galleryaddress)));
		emit Gallerycreated(address(galleryaddress), _owner);
	}

	///@notice create and mint nft in newly creatd gallery
	///@param gallerydata struct of the information related to gallery creation and nft minting
	///@dev parameter is passed as struct
	function mintNftInNewGallery(galleryAndNFT memory gallerydata) external override nonReentrant {
		bytes32 galleryid = findHash(gallerydata._id);
		require(!allgalleriesId.contains(galleryid), 'Id already registered');
		galleryInfo storage gallery = galleries[galleryid];
		allgalleriesId.add(galleryid);
		Gallery galleryaddress = new Gallery(gallerydata._id, gallerydata._owner, address(NFT), address(marketPlace));
		galleries[galleryid] = galleryInfo(
			gallerydata._owner,
			address(galleryaddress),
			gallerydata._id,
			IGallery(address(galleryaddress))
		);

		NFT.addManagers(address(galleryaddress));
		marketPlace.addGallery(address(galleryaddress), true);

		uint256 tokenid = gallery.gallery.mintAndSellNft(
			gallerydata._uri,
			gallerydata.artist,
			gallerydata.thirdParty,
			gallerydata.amount,
			gallerydata.artistSplit,
			gallerydata.galleryOwnerFee,
			gallerydata.artistFee,
			gallerydata.thirdPartyFee,
			gallerydata.expiryTime,
			gallerydata.physicalTwin
		);
		emit Mintednftinnewgallery(gallery.galleryAddress, gallery.owner, tokenid, gallery.galleryAddress);
	}

	///@notice list the gallery created from the gallery factory
	function listgallery()
		public
		view
		override
		returns (
			string[] memory name,
			address[] memory owner,
			address[] memory galleryAddress
		)
	{
		uint256 total = allgalleriesId.length();
		string[] memory name_ = new string[](total);
		address[] memory owner_ = new address[](total);
		address[] memory galleryaddress_ = new address[](total);

		for (uint256 i = 0; i < total; i++) {
			bytes32 id = allgalleriesId.at(i);
			name_[i] = galleries[id].name;
			owner_[i] = galleries[id].owner;
			galleryaddress_[i] = galleries[id].galleryAddress;
		}
		return (name_, owner_, galleryaddress_);
	}

	///@notice change the nft address
	///@param newnft address of new nft contract
	///@dev only owner can update nft contract address
	function changeNftAddress(address newnft) public override onlyOwner checkAddress(newnft) nonReentrant {
		NFT = INFT(newnft);
	}

	///@notice change the marketplace address
	///@param newMarket address of new marketplace contract
	///@dev only owner can update market place address
	function changeMarketAddress(address newMarket) public override onlyOwner checkAddress(newMarket) nonReentrant {
		marketPlace = IMarketPlace(newMarket);
	}

	///@notice calculates the hash of given string data
	///@dev internal function to assist hash calculation
	function findHash(string memory _data) private pure returns (bytes32) {
		return keccak256(abi.encodePacked(_data));
	}

	function galleryExists(string memory _name) public view returns (bool) {
		bytes32 galleryid = findHash(_name);
		return allgalleriesId.contains(galleryid);
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

	// function getApproved(uint256 tokenId) external view returns (address);
	// function isApprovedForAll(address owner, address operator) external view returns (bool);
	// function manageMinters(address user, bool status) external;

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
	struct tokenMarketInfo {
		uint256 tokenId;
		uint256 totalSell;
		uint256 minPrice;
		uint256 artistRoyalty;
		uint256 artistfee;
		uint256 galleryownerfee;
		uint256 thirdpartyfee;
		uint256 feeExpiryTime;
		bool onSell;
		address payable galleryOwner;
		address payable artist;
		address payable thirdParty;
		bool USD;
		address owner;
	}

	struct feeInfo {
		uint256 totalartistfee;
		// uint256 totalgalleryownerfee;
		uint256 totalplatformfee;
		uint256 totalthirdpartyfee;
	}

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
		// uint256 _artistRoyalty,
		uint256 _expirytime,
		address thirdParty,
		address _gallery,
		address _artist,
		bool USD
	) external;

	/*@notice cancel the sell 
    @params _tokenId id of the token to cancel the sell */
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

	//@notice get token info
	//@params tokenId to get information about
	function gettokeninfo(uint256 _tokenId) external view returns (tokenMarketInfo memory);

	function changePlatformAddress(address _platform) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IGalleryFactory {
	event Gallerycreated(address indexed galleryaddress, address indexed _creator);
	event Mintednftinnewgallery(
		address indexed galleryaddress,
		address indexed _owner,
		uint256 indexed tokenid,
		address minter
	);

	struct galleryAndNFT {
		string _id;
		address _owner;
		string _uri;
		// string _nftname;
		address artist;
		address thirdParty;
		uint256 amount;
		uint256 artistFee;
		uint256 galleryOwnerFee;
		uint256 artistSplit;
		uint256 thirdPartyFee;
		uint256 expiryTime;
		bool physicalTwin;
	}

	/* @notice create new gallery contract
        @param name name of the gallery
        @param _owner address of gallery owner*/
	function createGallery(string calldata _name, address _owner) external;

	///@notice creategallery and mint a NFT
	function mintNftInNewGallery(galleryAndNFT memory gallery) external;

	///@notice change address of nftcontract
	///@param newNft new address of the nftcontract
	function changeNftAddress(address newNft) external;

	///@notice change the address of marketcontract
	///@param newMarket new address of the marketcontract
	function changeMarketAddress(address newMarket) external;

	//get the information of gallery creacted
	function listgallery()
		external
		returns (
			string[] memory name,
			address[] memory owner,
			address[] memory galleryaddress
		);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IGallery {
	struct TokenInfo {
		string uri;
		uint256 tokenId;
		uint256 minprice;
		uint256 feeExpiryTime;
		address thirdParty;
		bool onSell;
		address artist;
		bool hasPhysicalTwin;
		uint256 totalSell;
		bool USD;
	}
	///feeInfo for nft
	struct FeeInfo {
		uint256 artistFee;
		uint256 gallerySplit;
		uint256 artistSplit;
		uint256 thirdPartyFee;
	}

	event Nftadded(uint256 indexed nftid, address indexed _artist);
	event Nftminted(uint256 indexed _tokenId, address indexed _minter);
	event Nftburned(uint256 indexed _tokenId, address indexed _from);
	event Transfered(uint256 indexed _tokenId, address indexed _from, address indexed _to);
	event Nftmintedandsold(uint256 indexed _tokenId, address indexed _minter, uint256 indexed _price);
	event Nftmintedandairdrop(uint256 indexed _tokenId, address indexed _receiver, address indexed _owner);
	event Nftmintedandairdropwithverification(uint256 indexed _tokenId, address indexed _owner);
	event NftAirdropped(uint256 indexed _tokenId, address indexed _reciever);

	/*@notice add nft to gallery*/
	// function addNft(string calldata _uri, string calldata _name) external;

	/*@notice mint Nft
    @param nftid id of nft to mint
    @param _to address to mint the token */
	function mintNFT(string calldata uri, address artist) external returns (uint256 tokenId);

	function mintAndSellNft(
		string memory _uri,
		address artist,
		address thirdParty,
		uint256 amount,
		uint256 artistSplit,
		uint256 gallerySplit,
		uint256 artistFee,
		uint256 thirdPartyFee,
		uint256 feeExpiryTime,
		bool physicalTwin
	) external returns (uint256 tokenId);

	// /*@notice get nft details
	// @param nftid  id of  nft to get details*/
	// function getNftdetails(bytes32 _nftid)
	// 	external
	// 	view
	// 	returns (
	// 		string memory tokenuri,
	// 		address[] memory owner,
	// 		address minter
	// 	);

	/* @notice transfer nft
    @param from address of current owner
    @param to address of new owner */
	function transferNft(
		address from,
		address to,
		uint256 tokenId
	) external;

	/*@notice burn token
    @param _tokenid id of token to be burned */
	function burn(uint256 _tokenId) external;

	/*@notice buynft
    @param tokenid id of token to be bought*/
	function buyNft(uint256 tokenid) external payable;

	/*@notice cancel the sell 
    @params _tokenId id of the token to cancel the sell */
	function cancelNftSell(uint256 _tokenid) external;

	/* @notice add token for sale
    @param _tokenId id of token
    @param amount minimum price to sell token*/
	function sellNft(
		uint256 tokenid,
		uint256 amount,
		FeeInfo memory feedata,
		address _thirdParty,
		uint256 _feeExpiryTime,
		bool physicalTwin,
		bool USD
	) external;

	/*@notice get token details
    @param tokenid  id of  token to get details*/
	function getTokendetails(uint256 tokenid)
		external
		view
		returns (
			string memory tokenuri,
			address owner,
			uint256 minprice,
			bool onSell,
			uint256 artistfee,
			uint256 galleryOwnerFee
		);

	//@notice get the list of token minted in gallery//
	function getListOfTokenIds() external view returns (uint256[] memory);

	//@notice get the list of nfts added in gallery//

	function retreiveBalance() external;
}

//SPDX-License-Identifier: Unlicensed

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../interface/IGallery.sol';
import '../interface/INFT.sol';
import '../interface/IMarketPlace.sol';

pragma solidity 0.8.10;

contract Gallery is ReentrancyGuard, Ownable, IGallery, Multicall, IERC721Receiver {
	///@notice map the given address with boolean
	///@dev checks whether the given address is added as admins or not
	mapping(address => bool) public admins;

	///@notice id of the gallery
	///@dev provides the unique id of this gallery
	string public id;

	///@notice address of the gallery owner
	///@dev provides the address of the gallery creator
	address public creator;

	///@dev instance of NFT contract
	INFT public nft;

	///@dev creates the instance of Marketplace contract
	IMarketPlace public market;

	///@notice blockNumber when contract is deployed
	///@dev provides blockNumber when contract is deployed
	uint256 public blockNumber;

	///@notice expirytime for airdrop in terms of hours
	uint256 public airDropTime;

	using EnumerableSet for EnumerableSet.AddressSet;
	using EnumerableSet for EnumerableSet.UintSet;

	constructor(
		string memory _id,
		address _owner, //gallery owner address
		address _nft,
		address _market // address _dollarmarket
	) checkAddress(_nft) checkAddress(_market) {
		id = _id;
		creator = _owner;
		nft = INFT(_nft);
		admins[_owner] = true;
		admins[msg.sender] = true;
		market = IMarketPlace(_market);
		transferOwnership(_owner);
		blockNumber = block.number;
		airDropTime = 72;
		// market_dollar = IMarketPlace(_dollarmarket);
	}

	///@notice checks if the address is zero address or not
	modifier checkAddress(address _contractaddress) {
		require(_contractaddress != address(0), 'Zero address');
		_;
	}

	///@notice to check whether the sender address is admin/owner or not
	///@dev modifier to check whether the sender address is admin/owner or not
	modifier _onlyAdminOrOwner(address _owner) {
		require(admins[_owner] || owner() == _owner, 'only owner/admin');
		_;
	}

	///@notice to check whether the sender address is owner of given token id or not
	///@dev modifier check whether the sender address is owner of given token id or not
	modifier onlyTokenOwner(uint256 tokenid) {
		address owner = address(nft.ownerOf(tokenid));
		require(owner == msg.sender, 'Only Token Owner');
		_;
	}

	///@notice to check whether the sender address is owner of given token id or not or the owner of the gallery
	///@dev modifier to check whether the sender address is owner of given token id or not or the owner of the gallery
	modifier onlyOwnerorTokenOwner(uint256 tokenid) {
		address tokenowner = nft.ownerOf(tokenid);
		if (tokenowner != msg.sender && owner() != msg.sender && !admins[msg.sender])
			revert('Only token-owner/gallery-owner');
		_;
	}

	struct AirDropInfo {
		uint256 tokenId;
		bytes32 verificationCode;
		bool isClaimed;
		address receiver;
		uint256 expiryTime;
	}

	EnumerableSet.UintSet private listOfTokenIds;
	EnumerableSet.UintSet private listOfTokenIdsForSale;
	EnumerableSet.UintSet private listofTokenAirDropped;

	mapping(uint256 => TokenInfo) public tokeninfo;
	mapping(uint256 => FeeInfo) public feeInfo;

	mapping(uint256 => AirDropInfo) public airDropInfo;

	receive() external payable {}

	///@notice Mint the nft through gallery
	///@param _uri token uri of the nft to be minted
	///@param _artist address of the artist of nft
	///@dev onlyAdmin or Owner of gallery can mint the nft
	function mintNFT(string memory _uri, address _artist)
		public
		override
		_onlyAdminOrOwner(msg.sender)
		nonReentrant
		returns (uint256)
	{
		uint256 tokenid = nft.mint(_uri, address(this));
		// if (owner() != creator) transferOwnership(creator);
		listOfTokenIds.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		Token.artist = _artist;
		emit Nftminted(tokenid, address(this));
		return tokenid;
	}

	///@notice burn the given token Id
	///@param _tokenId token id to burn
	///@dev only gallery owner or token owner can burn the given token id
	function burn(uint256 _tokenId) public override onlyOwnerorTokenOwner(_tokenId) nonReentrant {
		nft.burn(_tokenId);
		listOfTokenIds.remove(_tokenId);
		listOfTokenIdsForSale.remove(_tokenId);
		emit Nftburned(_tokenId, msg.sender);
	}

	///@notice transfer the given token Id
	///@param from address of current owner of the given tokenId
	///@param to address of new owner for the given tokenId
	///@param tokenId token id to transfer
	///@dev only gallery owner or token owner can transfer the given token id
	function transferNft(
		address from,
		address to,
		uint256 tokenId
	) public override onlyOwnerorTokenOwner(tokenId) nonReentrant {
		nft.safeTransferFrom(from, to, tokenId);
		emit Transfered(tokenId, from, to);
	}

	///@notice buy the given token id
	///@param tokenid token id to be bought by the buyer
	///@dev payable function
	function buyNft(uint256 tokenid) public payable override nonReentrant {
		require(listOfTokenIds.contains(tokenid), 'Tokenid N/A');
		TokenInfo storage Token = tokeninfo[tokenid];
		require(Token.onSell, 'Not on sell');
		listOfTokenIdsForSale.remove(tokenid);
		Token.onSell = false;
		Token.minprice = 0;
		Token.USD = false;

		market.buy{ value: msg.value }(tokenid, msg.sender);
		Token.totalSell = Token.totalSell + 1;
	}

	///@notice set the nft for sell
	///@param tokenId token id to be listed for sale
	///@param amount selling price of the token id
	///@param feeData tuple value containing fee information about nft(artistFee,gallerySplit,artistSplit,thirdPartyfee)
	///@param _thirdParty address of the thirdparty to recieve royalty on nft sell form second sell onwards
	///@param _feeExpiryTime time period till the thirdparty will recieve the royalty
	///@param physicalTwin flag to indicate physical twin is avaiable or not
	///@param USD boolean value to indicate pricing is in dollar or not
	///@dev function to list nft for sell and can be called only by galleryOwner or tokenOwner
	function sellNft(
		uint256 tokenId,
		uint256 amount,
		FeeInfo memory feeData,
		address _thirdParty,
		uint256 _feeExpiryTime,
		bool physicalTwin,
		bool USD
	) public override onlyOwnerorTokenOwner(tokenId) nonReentrant {
		require(listOfTokenIds.contains(tokenId), 'N/A in this gallery');
		TokenInfo storage Token = tokeninfo[tokenId];
		FeeInfo storage fee = feeInfo[tokenId];
		Token.tokenId = tokenId;
		Token.minprice = amount;
		Token.onSell = true;
		fee.artistFee = feeData.artistFee;
		fee.artistSplit = feeData.artistSplit;
		fee.thirdPartyFee = feeData.thirdPartyFee;
		Token.hasPhysicalTwin = physicalTwin;
		Token.USD = USD;
		fee.gallerySplit = feeData.gallerySplit;
		listOfTokenIdsForSale.add(tokenId);
		nft.setApprovalForAll(address(market), true);
		if (Token.totalSell == 0) {
			nft.setArtistRoyalty(tokenId, Token.artist, uint96(feeData.artistFee));
			Token.thirdParty = _thirdParty;
			Token.feeExpiryTime = calculateExpiryTime(_feeExpiryTime);
		}
		market.sell(
			tokenId,
			amount,
			feeData.artistSplit,
			feeData.gallerySplit,
			feeData.thirdPartyFee,
			Token.feeExpiryTime,
			_thirdParty,
			creator,
			Token.artist,
			USD
		);
	}

	///@notice mint the nft and list for sell
	///@param _uri token uri of the nft to be minted
	///@param artist address of the artist of nft
	///@param thirdParty address of the third party asssociated with nft
	///@param amount selling price of the token id
	///@param artistSplit spilt rate  artist will recieve while selling nft for first time
	///@param gallerySplit split rate to be transferred to gallery owner while selling nft
	///@param artistFee commission rate to be transferred to artist while selling nft
	///@param thirdPartyFee commission rate to be transferred to thirdparty while selling nft
	///@param feeExpiryTime time limit to pay third party commission fee
	///@param physicalTwin flag to indicate physical twin is avaiable or not
	///@dev function to mint the  nft and list it for  sell in a single transaction
	function mintAndSellNft(
		string calldata _uri,
		address artist,
		address thirdParty,
		uint256 amount,
		uint256 artistSplit,
		uint256 gallerySplit,
		uint256 artistFee,
		uint256 thirdPartyFee,
		uint256 feeExpiryTime,
		bool physicalTwin
	) public override returns (uint256 _tokenId) {
		uint256 tokenId = mintNFT(_uri, artist);
		FeeInfo memory feedata = FeeInfo(artistFee, gallerySplit, artistSplit, thirdPartyFee);
		sellNft(
			tokenId,
			amount,
			feedata,
			// feeInfo{artistFee,gallerySplit,artistSplit,thirdPartyFee},
			thirdParty,
			feeExpiryTime,
			physicalTwin,
			true
		);
		emit Nftmintedandsold(tokenId, address(this), amount);
		return tokenId;
	}

	///@notice cancel the nft listed for sell
	///@param _tokenId id of the token to be removed from list
	///@dev only gallery owner or token owner can cancel the sell of nft
	function cancelNftSell(uint256 _tokenId) public override onlyOwnerorTokenOwner(_tokenId) nonReentrant {
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		TokenInfo storage Token = tokeninfo[_tokenId];
		Token.minprice = 0;
		Token.onSell = false;
		Token.USD = false;
		listOfTokenIdsForSale.remove(_tokenId);
		market.cancelSell(_tokenId);
	}

	///@notice change the  artist commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _artistfee new artist fee commission rate
	///@dev only gallery owner or token owner can change  the artist commission rate for given  nft
	function changeArtistCommission(uint256 _tokenId, uint256 _artistfee)
		public
		onlyOwnerorTokenOwner(_tokenId)
		nonReentrant
	{
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		FeeInfo storage Fee = feeInfo[_tokenId];
		Fee.artistFee = _artistfee;
		market.changeArtistFee(_tokenId, _artistfee);
	}

	///@notice change the  gallery commission rate for given nft listed for sell
	///@param _tokenId id of the token
	///@param _gallerySplit new gallery owner fee commission rate
	///@dev only gallery owner or token owner can change  the gallery owner commission rate for given  nft
	function changeGalleryCommission(uint256 _tokenId, uint256 _gallerySplit)
		public
		onlyOwnerorTokenOwner(_tokenId)
		nonReentrant
	{
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		FeeInfo storage fee = feeInfo[_tokenId];
		fee.gallerySplit = _gallerySplit;
		market.changeGalleryFee(_tokenId, _gallerySplit);
	}

	///@notice change the  selling price of the listed nft
	///@param _tokenId id of the token
	///@param _minprice new selling price
	///@dev only gallery owner or token owner can change  the artist commission rate for given  nft
	function reSaleNft(uint256 _tokenId, uint256 _minprice) public onlyOwnerorTokenOwner(_tokenId) nonReentrant {
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		TokenInfo storage Token = tokeninfo[_tokenId];
		Token.minprice = _minprice;
		market.resale(_tokenId, _minprice);
	}

	///@notice list the token ids associated with this gallery
	function getListOfTokenIds() public view override returns (uint256[] memory) {
		return listOfTokenIds.values();
	}

	///@notice get the details of the given tokenid
	///@param tokenid id of the token whose detail is to be known
	function getTokendetails(uint256 tokenid)
		public
		view
		override
		returns (
			string memory tokenuri,
			address owner,
			uint256 minprice,
			bool onSell,
			uint256 artistfee,
			uint256 gallerySplit
		)
	{
		TokenInfo memory Token = tokeninfo[tokenid];
		FeeInfo memory fee = feeInfo[tokenid];
		address tokenowner = nft.ownerOf(tokenid);
		string memory uri = nft.tokenURI(tokenid);
		return (uri, tokenowner, Token.minprice, Token.onSell, fee.artistFee, fee.gallerySplit);
	}

	///@notice list the token ids listed for sale from this gallery
	function getListOfTokenOnSell() public view returns (uint256[] memory) {
		return listOfTokenIdsForSale.values();
	}

	///@notice retreive the balance accumulated with gallery contract
	///@dev only gallery owner can retreive the balance of gallery
	function retreiveBalance() public override onlyOwner nonReentrant {
		uint256 amount = address(this).balance;
		(bool success, ) = payable(msg.sender).call{ value: amount }(' ');
		require(success, 'Fail-to-retrieve');
	}

	///@notice initiate the airdrop feature
	///@dev approve the address to transfer nft on owner's behalf
	///@param _to address to approve
	///@param _tokenId tokenid to approve
	function manageAirDrop(address _to, uint256 _tokenId) public onlyOwner {
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		if (tokeninfo[_tokenId].onSell) cancelNftSell(_tokenId);
		listofTokenAirDropped.add(_tokenId);
		// require(!tokeninfo[tokenId].onSell, 'Token is on sell');
		nft.approve(_to, _tokenId);
		emit NftAirdropped(_tokenId, _to);
	}

	///@notice initiate the airdrop feature with verification code
	///@dev add verification code associated with  particular artswap token
	///@param _randomstring random string used as code to verify airdrop
	///@param _tokenid token Id of artswap token to be dropped
	function manageAirDropWithVerification(string memory _randomstring, uint256 _tokenid)
		public
		_onlyAdminOrOwner(msg.sender)
	{
		require(listOfTokenIds.contains(_tokenid), 'N/A in this gallery');
		if (tokeninfo[_tokenid].onSell) cancelNftSell(_tokenid);
		listofTokenAirDropped.add(_tokenid);
		AirDropInfo storage airdrop = airDropInfo[_tokenid];
		airdrop.tokenId = _tokenid;
		airdrop.isClaimed = false;
		airdrop.expiryTime = calculateExpiryTime(airDropTime);
		airdrop.verificationCode = getHash(_randomstring);
	}

	///@notice initiate the airdrop feature without tokenid
	///@dev mint token and approve the address to transfer nft on owner's behalf
	///@param to address to approve
	///@param _uri metadata of the nft
	///@param _artist address of the artist
	function mintandAirDrop(
		address to,
		string calldata _uri,
		address _artist
	) public _onlyAdminOrOwner(msg.sender) returns (uint256) {
		uint256 tokenid = nft.mint(_uri, address(this));
		listOfTokenIds.add(tokenid);
		listofTokenAirDropped.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		// Token.nftId = _id;
		Token.artist = _artist;
		nft.approve(to, tokenid);
		emit Nftmintedandairdrop(tokenid, to, address(this));
		return tokenid;
	}

	///@notice initiate the airdrop feature without tokenid
	///@dev mint token and store  the verification code to claim the airdropped token
	///@param _randomstring random string used as code to verify airdrop
	///@param _uri metadata of the nft
	///@param _artist address of the artist
	function mintandAirDropwithVerification(
		string memory _randomstring,
		string calldata _uri,
		address _artist
	) public _onlyAdminOrOwner(msg.sender) nonReentrant returns (uint256) {
		uint256 tokenid = nft.mint(_uri, address(this));
		listOfTokenIds.add(tokenid);
		listofTokenAirDropped.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		Token.artist = _artist;
		Token.feeExpiryTime = calculateExpiryTime(0);
		AirDropInfo storage airdrop = airDropInfo[tokenid];
		airdrop.tokenId = tokenid;
		airdrop.isClaimed = false;
		airdrop.verificationCode = getHash(_randomstring);
		airdrop.expiryTime = calculateExpiryTime(airDropTime);
		//  block.timestamp + airDropTime * 1 hours;
		emit Nftmintedandairdropwithverification(tokenid, address(this));
		return tokenid;
	}

	///@notice verify the airdrop feature enabled with verification code
	///@dev verify the verification code and transfer the specified tokenid to the specified new owner
	///@param _to new address to transfer the ownership
	///@param _tokenId nft id to transfer
	///@param _randomstring verification code associated with given nft
	function verifyAirDrop(
		address _to,
		uint256 _tokenId,
		string memory _randomstring
	) public {
		AirDropInfo storage airdrop = airDropInfo[_tokenId];
		bytes32 _code = getHash(_randomstring);
		require(airdrop.verificationCode == _code, 'Invalid Code');
		require(listOfTokenIds.contains(_tokenId), 'N/A in this gallery');
		require(block.timestamp <= airdrop.expiryTime, 'airdrop:expired');
		if (tokeninfo[_tokenId].onSell) cancelNftSell(_tokenId);
		airdrop.isClaimed = true;
		airdrop.receiver = _to;
		address owner = nft.ownerOf(_tokenId);
		nft.safeTransferFrom(owner, _to, _tokenId);
		emit NftAirdropped(_tokenId, _to);
	}

	///@notice changes the airdrop expiration time in terms of hour
	///@param _newtime new time in terms of hours
	///@dev only Admin or gallery owner can change the airdrop expiration time
	function changeAirDropTime(uint256 _newtime) public _onlyAdminOrOwner(msg.sender) nonReentrant {
		airDropTime = _newtime;
	}

	///@notice calculate the expiry time
	///@param time expiry time in terms of hours
	///@dev utils function to calculate expiry time
	function calculateExpiryTime(uint256 time) private view returns (uint256) {
		// uint256 timeToAdd = time * 365;
		return (block.timestamp + time * 1 hours);
	}

	///@notice generate the hash value
	///@dev generate the keccak256 hash of given input value
	///@param _string string value whose hash is to be calculated
	function getHash(string memory _string) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(_string));
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		// emit NFTReceived(operator, from, tokenId, data);
		return IERC721Receiver.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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