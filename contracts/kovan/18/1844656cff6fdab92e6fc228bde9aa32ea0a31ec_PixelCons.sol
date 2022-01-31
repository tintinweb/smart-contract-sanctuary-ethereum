/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity ^0.4.24;


/**
 * @title ERC721 Non-Fungible Token Standard Basic Interface
 * @dev Based on openzepplin open source ERC721 examples.
 * See (https://github.com/OpenZeppelin/openzeppelin-solidity)
 */
contract ERC721 {

	/**
	 * @dev 0x01ffc9a7 === 
	 *   bytes4(keccak256('supportsInterface(bytes4)'))
	 */
	bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;

	/**
	 * @dev 0x80ac58cd ===
	 *   bytes4(keccak256('balanceOf(address)')) ^
	 *   bytes4(keccak256('ownerOf(uint256)')) ^
	 *   bytes4(keccak256('approve(address,uint256)')) ^
	 *   bytes4(keccak256('getApproved(uint256)')) ^
	 *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
	 *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
	 *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
	 *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
	 *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
	 */
	bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;

	/**
	 * @dev 0x780e9d63 ===
	 *   bytes4(keccak256('totalSupply()')) ^
	 *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
	 *   bytes4(keccak256('tokenByIndex(uint256)'))
	 */
	bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;

	/**
	 * @dev 0x5b5e139f ===
	 *   bytes4(keccak256('name()')) ^
	 *   bytes4(keccak256('symbol()')) ^
	 *   bytes4(keccak256('tokenURI(uint256)'))
	 */
	bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;

	/** @dev A mapping of interface id to whether or not it is supported */
	mapping(bytes4 => bool) internal supportedInterfaces;

	/** @dev Token events */
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	/** @dev Registers ERC-165, ERC-721, ERC-721 Enumerable and ERC-721 Metadata as supported interfaces */
	constructor() public
	{
		registerInterface(InterfaceId_ERC165);
		registerInterface(InterfaceId_ERC721);
		registerInterface(InterfaceId_ERC721Enumerable);
		registerInterface(InterfaceId_ERC721Metadata);
	}

	/** @dev Internal function for registering an interface */
	function registerInterface(bytes4 _interfaceId) internal
	{
		require(_interfaceId != 0xffffffff);
		supportedInterfaces[_interfaceId] = true;
	}

	/** @dev ERC-165 interface implementation */
	function supportsInterface(bytes4 _interfaceId) external view returns(bool)
	{
		return supportedInterfaces[_interfaceId];
	}

	/** @dev ERC-721 interface */
	function balanceOf(address _owner) public view returns(uint256 _balance);
	function ownerOf(uint256 _tokenId) public view returns(address _owner);
	function approve(address _to, uint256 _tokenId) public;
	function getApproved(uint256 _tokenId) public view returns(address _operator);
	function setApprovalForAll(address _operator, bool _approved) public;
	function isApprovedForAll(address _owner, address _operator) public view returns(bool);
	function transferFrom(address _from, address _to, uint256 _tokenId) public;
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public;

	/** @dev ERC-721 Enumerable interface */
	function totalSupply() public view returns(uint256 _total);
	function tokenByIndex(uint256 _index) public view returns(uint256 _tokenId);
	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns(uint256 _tokenId);

	/** @dev ERC-721 Metadata interface */
	function name() public view returns(string _name);
	function symbol() public view returns(string _symbol);
	function tokenURI(uint256 _tokenId) public view returns(string);
}


/**
 * @title PixelCons Core
 * @notice The purpose of this contract is to provide a shared ecosystem of minimal pixel art tokens for everyone to use. All users are treated 
 * equally with the exception of an admin user who only controls the ERC721 metadata function which points to the app website. No fees are 
 * required to interact with this contract beyond base gas fees. Here are a few notes on the basic workings of the contract:
 *    PixelCons [The core ERC721 token of this contract]
 *        -Each PixelCon is unique with an ID that encodes all its pixel data
 *        -PixelCons can be identified by both TokenIDs and TokenIndexes (index requires fewer bits to store)
 *        -A PixelCon can never be destroyed
 *        -Total number of PixelCons is limited to 18,446,744,073,709,551,616 (2^64)
 *        -A single account can only hold 4,294,967,296 PixelCons (2^32)
 *    Collections [Grouping mechanism for associating PixelCons together]
 *        -Collections are identified by an index (zero is invalid)
 *        -Collections can only be created by a user who both created and currently owns all its PixelCons
 *        -Total number of collections is limited to 18,446,744,073,709,551,616 (2^64)
 * For more information about PixelCons, please visit (https://pixelcons.io)
 * @dev This contract follows the ERC721 token standard with additional functions for creating, grouping, etc.
 * See (https://github.com/OpenZeppelin/openzeppelin-solidity)
 * @author PixelCons
 */
contract PixelCons is ERC721 {

	using AddressUtils for address;

	/** @dev Equal to 'bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))' */
	bytes4 private constant ERC721_RECEIVED = 0x150b7a02;


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////// Structs ///////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/** @dev The main PixelCon struct */
	struct PixelCon {
		uint256 tokenId;
		//// ^256bits ////
		address creator;
		uint64 collectionIndex;
		uint32 dateCreated;
	}

	/** @dev A struct linking a token owner with its token index */
	struct TokenLookup {
		address owner;
		uint64 tokenIndex;
		uint32 ownedIndex;
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////// Storage ///////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/**  @dev The address thats allowed to withdraw volunteered funds sent to this contract */
	address internal admin;

	/** @dev The URI template for retrieving token metadata */
	string internal tokenURITemplate;

	////////////////// PixelCon Tokens //////////////////

	/** @dev Mapping from token ID to owner/index */
	mapping(uint256 => TokenLookup) internal tokenLookup;

	/**  @dev Mapping from owner to token indexes */
	mapping(address => uint64[]) internal ownedTokens;

	/**  @dev Mapping from creator to token indexes */
	mapping(address => uint64[]) internal createdTokens;

	/** @dev Mapping from token ID to approved address */
	mapping(uint256 => address) internal tokenApprovals;

	/** @dev Mapping from owner to operator approvals */
	mapping(address => mapping(address => bool)) internal operatorApprovals;

	/** @dev An array containing all PixelCons in existence */
	PixelCon[] internal pixelcons;

	/** @dev An array that mirrors 'pixelcons' in terms of indexing, but stores only name data */
	bytes8[] internal pixelconNames;

	////////////////// Collections //////////////////

	/** @dev Mapping from collection index to token indexes */
	mapping(uint64 => uint64[]) internal collectionTokens;

	/** @dev An array that mirrors 'collectionTokens' in terms of indexing, but stores only name data */
	bytes8[] internal collectionNames;


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	///////////////////////////////////////////////////////////// Events ////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/** @dev PixelCon token events */
	event Create(uint256 indexed _tokenId, address indexed _creator, uint64 _tokenIndex, address _to);
	event Rename(uint256 indexed _tokenId, bytes8 _newName);

	/**  @dev PixelCon collection events */
	event CreateCollection(address indexed _creator, uint64 indexed _collectionIndex);
	event RenameCollection(uint64 indexed _collectionIndex, bytes8 _newName);
	event ClearCollection(uint64 indexed _collectionIndex);


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////// Modifiers ///////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/**  @dev Small validators for quick validation of function parameters */
	modifier validIndex(uint64 _index) {
		require(_index != uint64(0), "Invalid index");
		_;
	}
	modifier validId(uint256 _id) {
		require(_id != uint256(0), "Invalid ID");
		_;
	}
	modifier validAddress(address _address) {
		require(_address != address(0), "Invalid address");
		_;
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////// PixelCons Core ///////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * @notice Contract constructor
	 */
	constructor() public
	{
		//admin defaults to the contract creator
		admin = msg.sender;

		//fill zero index pixelcon collection
		collectionNames.length++;
	}

	/**
	 * @notice Get the current admin
	 * @return The current admin
	 */
	function getAdmin() public view returns(address)
	{
		return admin;
	}

	/**
	 * @notice Withdraw all volunteered funds to `(_to)`
	 * @param _to Address to withdraw the funds to
	 */
	function adminWithdraw(address _to) public
	{
		require(msg.sender == admin, "Only the admin can call this function");
		_to.transfer(address(this).balance);
	}

	/**
	 * @notice Change the admin to `(_to)`
	 * @param _newAdmin New admin address
	 */
	function adminChange(address _newAdmin) public
	{
		require(msg.sender == admin, "Only the admin can call this function");
		admin = _newAdmin;
	}

	/**
	 * @notice Change the token URI template
	 * @param _newTokenURITemplate New token URI template
	 */
	function adminSetTokenURITemplate(string _newTokenURITemplate) public
	{
		require(msg.sender == admin, "Only the admin can call this function");
		tokenURITemplate = _newTokenURITemplate;
	}

	////////////////// PixelCon Tokens //////////////////

	/**
	 * @notice Create PixelCon `(_tokenId)`
	 * @dev Throws if the token ID already exists
	 * @param _to Address that will own the PixelCon
	 * @param _tokenId ID of the PixelCon to be creates
	 * @param _name PixelCon name (not required)
	 * @return The index of the new PixelCon
	 */
	function create(address _to, uint256 _tokenId, bytes8 _name) public payable validAddress(_to) validId(_tokenId) returns(uint64)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(pixelcons.length < uint256(2 ** 64) - 1, "Max number of PixelCons has been reached");
		require(lookupData.owner == address(0), "PixelCon already exists");

		//get created timestamp (zero as date indicates null)
		uint32 dateCreated = 0;
		if (now < uint256(2 ** 32)) dateCreated = uint32(now);

		//create PixelCon token and set owner
		uint64 index = uint64(pixelcons.length);
		lookupData.tokenIndex = index;
		pixelcons.length++;
		pixelconNames.length++;
		PixelCon storage pixelcon = pixelcons[index];
		pixelcon.tokenId = _tokenId;
		pixelcon.creator = msg.sender;
		pixelcon.dateCreated = dateCreated;
		pixelconNames[index] = _name;
		uint64[] storage createdList = createdTokens[msg.sender];
		uint createdListIndex = createdList.length;
		createdList.length++;
		createdList[createdListIndex] = index;
		addTokenTo(_to, _tokenId);

		emit Create(_tokenId, msg.sender, index, _to);
		emit Transfer(address(0), _to, _tokenId);
		return index;
	}

	/**
	 * @notice Rename PixelCon `(_tokenId)`
	 * @dev Throws if the caller is not the owner and creator of the token
	 * @param _tokenId ID of the PixelCon to rename
	 * @param _name New name
	 * @return The index of the PixelCon
	 */
	function rename(uint256 _tokenId, bytes8 _name) public validId(_tokenId) returns(uint64)
	{
		require(isCreatorAndOwner(msg.sender, _tokenId), "Sender is not the creator and owner");

		//update name
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		pixelconNames[lookupData.tokenIndex] = _name;

		emit Rename(_tokenId, _name);
		return lookupData.tokenIndex;
	}

	/**
	 * @notice Check if PixelCon `(_tokenId)` exists
	 * @param _tokenId ID of the PixelCon to query the existence of
	 * @return True if the PixelCon exists
	 */
	function exists(uint256 _tokenId) public view validId(_tokenId) returns(bool)
	{
		address owner = tokenLookup[_tokenId].owner;
		return owner != address(0);
	}

	/**
	 * @notice Get the creator of PixelCon `(_tokenId)`
	 * @dev Throws if PixelCon does not exist
	 * @param _tokenId ID of the PixelCon to query the creator of
	 * @return Creator address for PixelCon
	 */
	function creatorOf(uint256 _tokenId) public view validId(_tokenId) returns(address)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner != address(0), "PixelCon does not exist");

		return pixelcons[lookupData.tokenIndex].creator;
	}

	/**
	 * @notice Get the total number of PixelCons created by `(_creator)`
	 * @param _creator Address to query the total of
	 * @return Total number of PixelCons created by given address
	 */
	function creatorTotal(address _creator) public view validAddress(_creator) returns(uint256)
	{
		return createdTokens[_creator].length;
	}

	/**
	 * @notice Enumerate PixelCon created by `(_creator)`
	 * @dev Throws if index is out of bounds
	 * @param _creator Creator address
	 * @param _index Counter less than `creatorTotal(_creator)`
	 * @return PixelCon ID for the `(_index)`th PixelCon created by `(_creator)`
	 */
	function tokenOfCreatorByIndex(address _creator, uint256 _index) public view validAddress(_creator) returns(uint256)
	{
		require(_index < createdTokens[_creator].length, "Index is out of bounds");
		PixelCon storage pixelcon = pixelcons[createdTokens[_creator][_index]];
		return pixelcon.tokenId;
	}

	/**
	 * @notice Get all details of PixelCon `(_tokenId)`
	 * @dev Throws if PixelCon does not exist
	 * @param _tokenId ID of the PixelCon to get details for
	 * @return PixelCon details
	 */
	function getTokenData(uint256 _tokenId) public view validId(_tokenId)
	returns(uint256 _tknId, uint64 _tknIdx, uint64 _collectionIdx, address _owner, address _creator, bytes8 _name, uint32 _dateCreated)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner != address(0), "PixelCon does not exist");

		PixelCon storage pixelcon = pixelcons[lookupData.tokenIndex];
		return (pixelcon.tokenId, lookupData.tokenIndex, pixelcon.collectionIndex, lookupData.owner,
			pixelcon.creator, pixelconNames[lookupData.tokenIndex], pixelcon.dateCreated);
	}

	/**
	 * @notice Get all details of PixelCon #`(_tokenIndex)`
	 * @dev Throws if PixelCon does not exist
	 * @param _tokenIndex Index of the PixelCon to get details for
	 * @return PixelCon details
	 */
	function getTokenDataByIndex(uint64 _tokenIndex) public view
	returns(uint256 _tknId, uint64 _tknIdx, uint64 _collectionIdx, address _owner, address _creator, bytes8 _name, uint32 _dateCreated)
	{
		require(_tokenIndex < totalSupply(), "PixelCon index is out of bounds");

		PixelCon storage pixelcon = pixelcons[_tokenIndex];
		TokenLookup storage lookupData = tokenLookup[pixelcon.tokenId];
		return (pixelcon.tokenId, lookupData.tokenIndex, pixelcon.collectionIndex, lookupData.owner,
			pixelcon.creator, pixelconNames[lookupData.tokenIndex], pixelcon.dateCreated);
	}

	/**
	 * @notice Get the index of PixelCon `(_tokenId)`
	 * @dev Throws if PixelCon does not exist
	 * @param _tokenId ID of the PixelCon to query the index of
	 * @return Index of the given PixelCon ID
	 */
	function getTokenIndex(uint256 _tokenId) validId(_tokenId) public view returns(uint64)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner != address(0), "PixelCon does not exist");

		return lookupData.tokenIndex;
	}

	////////////////// Collections //////////////////

	/**
	 * @notice Create PixelCon collection
	 * @dev Throws if the message sender is not the owner and creator of the given tokens
	 * @param _tokenIndexes Token indexes to group together into a collection
	 * @param _name Name of the collection
	 * @return Index of the new collection
	 */
	function createCollection(uint64[] _tokenIndexes, bytes8 _name) public returns(uint64)
	{
		require(collectionNames.length < uint256(2 ** 64) - 1, "Max number of collections has been reached");
		require(_tokenIndexes.length > 1, "Collection must contain more than one PixelCon");

		//loop through given indexes to add to collection and check additional requirements
		uint64 collectionIndex = uint64(collectionNames.length);
		uint64[] storage collection = collectionTokens[collectionIndex];
		collection.length = _tokenIndexes.length;
		for (uint i = 0; i < _tokenIndexes.length; i++) {
			uint64 tokenIndex = _tokenIndexes[i];
			require(tokenIndex < totalSupply(), "PixelCon index is out of bounds");

			PixelCon storage pixelcon = pixelcons[tokenIndex];
			require(isCreatorAndOwner(msg.sender, pixelcon.tokenId), "Sender is not the creator and owner of the PixelCons");
			require(pixelcon.collectionIndex == uint64(0), "PixelCon is already in a collection");

			pixelcon.collectionIndex = collectionIndex;
			collection[i] = tokenIndex;
		}
		collectionNames.length++;
		collectionNames[collectionIndex] = _name;

		emit CreateCollection(msg.sender, collectionIndex);
		return collectionIndex;
	}

	/**
	 * @notice Rename collection #`(_collectionIndex)`
	 * @dev Throws if the message sender is not the owner and creator of all collection tokens
	 * @param _collectionIndex Index of the collection to rename
	 * @param _name New name
	 * @return Index of the collection
	 */
	function renameCollection(uint64 _collectionIndex, bytes8 _name) validIndex(_collectionIndex) public returns(uint64)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");

		//loop through the collections token indexes and check additional requirements
		uint64[] storage collection = collectionTokens[_collectionIndex];
		require(collection.length > 0, "Collection has been cleared");
		for (uint i = 0; i < collection.length; i++) {
			PixelCon storage pixelcon = pixelcons[collection[i]];
			require(isCreatorAndOwner(msg.sender, pixelcon.tokenId), "Sender is not the creator and owner of the PixelCons");
		}

		//update
		collectionNames[_collectionIndex] = _name;

		emit RenameCollection(_collectionIndex, _name);
		return _collectionIndex;
	}

	/**
	 * @notice Clear collection #`(_collectionIndex)`
	 * @dev Throws if the message sender is not the owner and creator of all collection tokens
	 * @param _collectionIndex Index of the collection to clear out
	 * @return Index of the collection
	 */
	function clearCollection(uint64 _collectionIndex) validIndex(_collectionIndex) public returns(uint64)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");

		//loop through the collections token indexes and check additional requirements while clearing pixelcon collection index
		uint64[] storage collection = collectionTokens[_collectionIndex];
		require(collection.length > 0, "Collection is already cleared");
		for (uint i = 0; i < collection.length; i++) {
			PixelCon storage pixelcon = pixelcons[collection[i]];
			require(isCreatorAndOwner(msg.sender, pixelcon.tokenId), "Sender is not the creator and owner of the PixelCons");

			pixelcon.collectionIndex = 0;
		}

		//clear out collection data
		delete collectionNames[_collectionIndex];
		delete collectionTokens[_collectionIndex];

		emit ClearCollection(_collectionIndex);
		return _collectionIndex;
	}

	/**
	 * @notice Check if collection #`(_collectionIndex)` exists
	 * @param _collectionIndex Index of the collection to query the existence of
	 * @return True if collection exists
	 */
	function collectionExists(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(bool)
	{
		return _collectionIndex < totalCollections();
	}

	/**
	 * @notice Check if collection #`(_collectionIndex)` has been cleared
	 * @dev Throws if the collection index is out of bounds
	 * @param _collectionIndex Index of the collection to query the state of
	 * @return True if collection has been cleared
	 */
	function collectionCleared(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(bool)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");
		return collectionTokens[_collectionIndex].length == uint256(0);
	}

	/**
	 * @notice Get the total number of collections
	 * @return Total number of collections
	 */
	function totalCollections() public view returns(uint256)
	{
		return collectionNames.length;
	}

	/**
	 * @notice Get the collection index of PixelCon `(_tokenId)`
	 * @dev Throws if the PixelCon does not exist
	 * @param _tokenId ID of the PixelCon to query the collection of
	 * @return Collection index of given PixelCon
	 */
	function collectionOf(uint256 _tokenId) public view validId(_tokenId) returns(uint256)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner != address(0), "PixelCon does not exist");

		return pixelcons[tokenLookup[_tokenId].tokenIndex].collectionIndex;
	}

	/**
	 * @notice Get the total number of PixelCons in collection #`(_collectionIndex)`
	 * @dev Throws if the collection does not exist
	 * @param _collectionIndex Collection index to query the total of
	 * @return Total number of PixelCons in the collection
	 */
	function collectionTotal(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(uint256)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");
		return collectionTokens[_collectionIndex].length;
	}

	/**
	 * @notice Get the name of collection #`(_collectionIndex)`
	 * @dev Throws if the collection does not exist
	 * @param _collectionIndex Collection index to query the name of
	 * @return Collection name
	 */
	function getCollectionName(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(bytes8)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");
		return collectionNames[_collectionIndex];
	}

	/**
	 * @notice Enumerate PixelCon in collection #`(_collectionIndex)`
	 * @dev Throws if the collection does not exist or index is out of bounds
	 * @param _collectionIndex Collection index
	 * @param _index Counter less than `collectionTotal(_collection)`
	 * @return PixelCon ID for the `(_index)`th PixelCon in collection #`(_collectionIndex)`
	 */
	function tokenOfCollectionByIndex(uint64 _collectionIndex, uint256 _index) public view validIndex(_collectionIndex) returns(uint256)
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");
		require(_index < collectionTokens[_collectionIndex].length, "Index is out of bounds");
		PixelCon storage pixelcon = pixelcons[collectionTokens[_collectionIndex][_index]];
		return pixelcon.tokenId;
	}

	////////////////// Web3 Only //////////////////

	/**
	 * @notice Get the indexes of all PixelCons owned by `(_owner)`
	 * @dev This function is for web3 calls only, as it returns a dynamic array
	 * @param _owner Owner address
	 * @return PixelCon indexes
	 */
	function getForOwner(address _owner) public view validAddress(_owner) returns(uint64[])
	{
		return ownedTokens[_owner];
	}

	/**
	 * @notice Get the indexes of all PixelCons created by `(_creator)`
	 * @dev This function is for web3 calls only, as it returns a dynamic array
	 * @param _creator Creator address 
	 * @return PixelCon indexes
	 */
	function getForCreator(address _creator) public view validAddress(_creator) returns(uint64[])
	{
		return createdTokens[_creator];
	}

	/**
	 * @notice Get the indexes of all PixelCons in collection #`(_collectionIndex)`
	 * @dev This function is for web3 calls only, as it returns a dynamic array
	 * @param _collectionIndex Collection index
	 * @return PixelCon indexes
	 */
	function getForCollection(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(uint64[])
	{
		return collectionTokens[_collectionIndex];
	}

	/**
	 * @notice Get the basic data for the given PixelCon indexes
	 * @dev This function is for web3 calls only, as it returns a dynamic array
	 * @param _tokenIndexes List of PixelCon indexes
	 * @return All PixelCon basic data
	 */
	function getBasicData(uint64[] _tokenIndexes) public view returns(uint256[], bytes8[], address[], uint64[])
	{
		uint256[] memory tokenIds = new uint256[](_tokenIndexes.length);
		bytes8[] memory names = new bytes8[](_tokenIndexes.length);
		address[] memory owners = new address[](_tokenIndexes.length);
		uint64[] memory collectionIdxs = new uint64[](_tokenIndexes.length);

		for (uint i = 0; i < _tokenIndexes.length; i++)	{
			uint64 tokenIndex = _tokenIndexes[i];
			require(tokenIndex < totalSupply(), "PixelCon index is out of bounds");

			tokenIds[i] = pixelcons[tokenIndex].tokenId;
			names[i] = pixelconNames[tokenIndex];
			owners[i] = tokenLookup[pixelcons[tokenIndex].tokenId].owner;
			collectionIdxs[i] = pixelcons[tokenIndex].collectionIndex;
		}
		return (tokenIds, names, owners, collectionIdxs);
	}

	/**
	 * @notice Get the names of all PixelCons
	 * @dev This function is for web3 calls only, as it returns a dynamic array
	 * @return The names of all PixelCons in existence
	 */
	function getAllNames() public view returns(bytes8[])
	{
		return pixelconNames;
	}

	/**
	 * @notice Get the names of all PixelCons from index `(_startIndex)` to `(_endIndex)`
	 * @dev This function is for web3 calls only, as it returns a dynamic array
	 * @return The names of the PixelCons in the given range
	 */
	function getNamesInRange(uint64 _startIndex, uint64 _endIndex) public view returns(bytes8[])
	{
		require(_startIndex <= totalSupply(), "Start index is out of bounds");
		require(_endIndex <= totalSupply(), "End index is out of bounds");
		require(_startIndex <= _endIndex, "End index is less than the start index");

		uint64 length = _endIndex - _startIndex;
		bytes8[] memory names = new bytes8[](length);
		for (uint i = 0; i < length; i++)	{
			names[i] = pixelconNames[_startIndex + i];
		}
		return names;
	}

	/**
	 * @notice Get details of collection #`(_collectionIndex)`
	 * @dev This function is for web3 calls only, as it returns a dynamic array
	 * @param _collectionIndex Index of the collection to get the data of
	 * @return Collection name and included PixelCon indexes
	 */
	function getCollectionData(uint64 _collectionIndex) public view validIndex(_collectionIndex) returns(bytes8, uint64[])
	{
		require(_collectionIndex < totalCollections(), "Collection does not exist");
		return (collectionNames[_collectionIndex], collectionTokens[_collectionIndex]);
	}

	/**
	 * @notice Get the names of all collections
	 * @dev This function is for web3 calls only, as it returns a dynamic array
	 * @return The names of all PixelCon collections in existence
	 */
	function getAllCollectionNames() public view returns(bytes8[])
	{
		return collectionNames;
	}

	/**
	 * @notice Get the names of all collections from index `(_startIndex)` to `(_endIndex)`
	 * @dev This function is for web3 calls only, as it returns a dynamic array
	 * @return The names of the collections in the given range
	 */
	function getCollectionNamesInRange(uint64 _startIndex, uint64 _endIndex) public view returns(bytes8[])
	{
		require(_startIndex <= totalCollections(), "Start index is out of bounds");
		require(_endIndex <= totalCollections(), "End index is out of bounds");
		require(_startIndex <= _endIndex, "End index is less than the start index");

		uint64 length = _endIndex - _startIndex;
		bytes8[] memory names = new bytes8[](length);
		for (uint i = 0; i < length; i++)	{
			names[i] = collectionNames[_startIndex + i];
		}
		return names;
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////// ERC-721 Implementation ///////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * @notice Get the balance of `(_owner)`
	 * @param _owner Owner address
	 * @return Owner balance
	 */
	function balanceOf(address _owner) public view validAddress(_owner) returns(uint256)
	{
		return ownedTokens[_owner].length;
	}

	/**
	 * @notice Get the owner of PixelCon `(_tokenId)`
	 * @dev Throws if PixelCon does not exist
	 * @param _tokenId ID of the token
	 * @return Owner of the given PixelCon
	 */
	function ownerOf(uint256 _tokenId) public view validId(_tokenId) returns(address)
	{
		address owner = tokenLookup[_tokenId].owner;
		require(owner != address(0), "PixelCon does not exist");
		return owner;
	}

	/**
	 * @notice Approve `(_to)` to transfer PixelCon `(_tokenId)` (zero indicates no approved address)
	 * @dev Throws if not called by the owner or an approved operator
	 * @param _to Address to be approved
	 * @param _tokenId ID of the token to be approved
	 */
	function approve(address _to, uint256 _tokenId) public validId(_tokenId)
	{
		address owner = tokenLookup[_tokenId].owner;
		require(_to != owner, "Cannot approve PixelCon owner");
		require(msg.sender == owner || operatorApprovals[owner][msg.sender], "Sender does not have permission to approve address");

		tokenApprovals[_tokenId] = _to;
		emit Approval(owner, _to, _tokenId);
	}

	/**
	 * @notice Get the approved address for PixelCon `(_tokenId)`
	 * @dev Throws if the PixelCon does not exist
	 * @param _tokenId ID of the token
	 * @return Address currently approved for the given PixelCon
	 */
	function getApproved(uint256 _tokenId) public view validId(_tokenId) returns(address)
	{
		address owner = tokenLookup[_tokenId].owner;
		require(owner != address(0), "PixelCon does not exist");
		return tokenApprovals[_tokenId];
	}

	/**
	 * @notice Set or unset the approval of operator `(_to)`
	 * @dev An operator is allowed to transfer all tokens of the sender on their behalf
	 * @param _to Operator address to set the approval
	 * @param _approved Flag for setting approval
	 */
	function setApprovalForAll(address _to, bool _approved) public validAddress(_to)
	{
		require(_to != msg.sender, "Cannot approve self");
		operatorApprovals[msg.sender][_to] = _approved;
		emit ApprovalForAll(msg.sender, _to, _approved);
	}

	/**
	 * @notice Get if `(_operator)` is an approved operator for owner `(_owner)`
	 * @param _owner Owner address 
	 * @param _operator Operator address
	 * @return True if the given operator is approved by the given owner
	 */
	function isApprovedForAll(address _owner, address _operator) public view validAddress(_owner) validAddress(_operator) returns(bool)
	{
		return operatorApprovals[_owner][_operator];
	}

	/**
	 * @notice Transfer the ownership of PixelCon `(_tokenId)` to `(_to)` (try to use 'safeTransferFrom' instead)
	 * @dev Throws if the sender is not the owner, approved, or operator
	 * @param _from Current owner
	 * @param _to Address to receive the PixelCon
	 * @param _tokenId ID of the PixelCon to be transferred
	 */
	function transferFrom(address _from, address _to, uint256 _tokenId) public validAddress(_from) validAddress(_to) validId(_tokenId)
	{
		require(isApprovedOrOwner(msg.sender, _tokenId), "Sender does not have permission to transfer PixelCon");
		clearApproval(_from, _tokenId);
		removeTokenFrom(_from, _tokenId);
		addTokenTo(_to, _tokenId);

		emit Transfer(_from, _to, _tokenId);
	}

	/**
	 * @notice Safely transfer the ownership of PixelCon `(_tokenId)` to `(_to)`
	 * @dev Throws if receiver is a contract that does not respond or the sender is not the owner, approved, or operator
	 * @param _from Current owner
	 * @param _to Address to receive the PixelCon
	 * @param _tokenId ID of the PixelCon to be transferred
	 */
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) public
	{
		//requirements are checked in 'transferFrom' function
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	/**
	 * @notice Safely transfer the ownership of PixelCon `(_tokenId)` to `(_to)`
	 * @dev Throws if receiver is a contract that does not respond or the sender is not the owner, approved, or operator
	 * @param _from Current owner
	 * @param _to Address to receive the PixelCon
	 * @param _tokenId ID of the PixelCon to be transferred
	 * @param _data Data to send along with a safe transfer check
	 */
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) public
	{
		//requirements are checked in 'transferFrom' function
		transferFrom(_from, _to, _tokenId);
		require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data), "Transfer was not safe");
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////// ERC-721 Enumeration Implementation /////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * @notice Get the total number of PixelCons in existence
	 * @return Total number of PixelCons in existence
	 */
	function totalSupply() public view returns(uint256)
	{
		return pixelcons.length;
	}

	/**
	 * @notice Get the ID of PixelCon #`(_tokenIndex)`
	 * @dev Throws if index is out of bounds
	 * @param _tokenIndex Counter less than `totalSupply()`
	 * @return `_tokenIndex`th PixelCon ID
	 */
	function tokenByIndex(uint256 _tokenIndex) public view returns(uint256)
	{
		require(_tokenIndex < totalSupply(), "PixelCon index is out of bounds");
		return pixelcons[_tokenIndex].tokenId;
	}

	/**
	 * @notice Enumerate PixelCon assigned to owner `(_owner)`
	 * @dev Throws if the index is out of bounds
	 * @param _owner Owner address
	 * @param _index Counter less than `balanceOf(_owner)`
	 * @return PixelCon ID for the `(_index)`th PixelCon in owned by `(_owner)`
	 */
	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view validAddress(_owner) returns(uint256)
	{
		require(_index < ownedTokens[_owner].length, "Index is out of bounds");
		PixelCon storage pixelcon = pixelcons[ownedTokens[_owner][_index]];
		return pixelcon.tokenId;
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////// ERC-721 Metadata Implementation //////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * @notice Get the name of this contract token
	 * @return Contract token name
	 */
	function name() public view returns(string)
	{
		return "PixelCons";
	}

	/**
	 * @notice Get the symbol for this contract token
	 * @return Contract token symbol
	 */
	function symbol() public view returns(string)
	{
		return "PXCN";
	}

	/**
	 * @notice Get a distinct Uniform Resource Identifier (URI) for PixelCon `(_tokenId)`
	 * @dev Throws if the given PixelCon does not exist
	 * @return PixelCon URI
	 */
	function tokenURI(uint256 _tokenId) public view returns(string)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner != address(0), "PixelCon does not exist");
		PixelCon storage pixelcon = pixelcons[lookupData.tokenIndex];
		bytes8 pixelconName = pixelconNames[lookupData.tokenIndex];

		//Available values: <tokenId>, <tokenIndex>, <name>, <owner>, <creator>, <dateCreated>, <collectionIndex>

		//start with the token URI template and replace in the appropriate values
		string memory finalTokenURI = tokenURITemplate;
		finalTokenURI = StringUtils.replace(finalTokenURI, "<tokenId>", StringUtils.toHexString(_tokenId, 32));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<tokenIndex>", StringUtils.toHexString(uint256(lookupData.tokenIndex), 8));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<name>", StringUtils.toHexString(uint256(pixelconName), 8));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<owner>", StringUtils.toHexString(uint256(lookupData.owner), 20));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<creator>", StringUtils.toHexString(uint256(pixelcon.creator), 20));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<dateCreated>", StringUtils.toHexString(uint256(pixelcon.dateCreated), 8));
		finalTokenURI = StringUtils.replace(finalTokenURI, "<collectionIndex>", StringUtils.toHexString(uint256(pixelcon.collectionIndex), 8));

		return finalTokenURI;
	}


	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////// Utils ////////////////////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	/**
	 * @notice Check whether the given editor is the current owner and original creator of a given token ID
	 * @param _address Address to check for
	 * @param _tokenId ID of the token to be edited
	 * @return True if the editor is approved for the given token ID, is an operator of the owner, or is the owner of the token
	 */
	function isCreatorAndOwner(address _address, uint256 _tokenId) internal view returns(bool)
	{
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		address owner = lookupData.owner;
		address creator = pixelcons[lookupData.tokenIndex].creator;

		return (_address == owner && _address == creator);
	}

	/**
	 * @notice Check whether the given spender can transfer a given token ID
	 * @dev Throws if the PixelCon does not exist
	 * @param _address Address of the spender to query
	 * @param _tokenId ID of the token to be transferred
	 * @return True if the spender is approved for the given token ID, is an operator of the owner, or is the owner of the token
	 */
	function isApprovedOrOwner(address _address, uint256 _tokenId) internal view returns(bool)
	{
		address owner = tokenLookup[_tokenId].owner;
		require(owner != address(0), "PixelCon does not exist");
		return (_address == owner || tokenApprovals[_tokenId] == _address || operatorApprovals[owner][_address]);
	}

	/**
	 * @notice Clear current approval of a given token ID
	 * @dev Throws if the given address is not indeed the owner of the token
	 * @param _owner Owner of the token
	 * @param _tokenId ID of the token to be transferred
	 */
	function clearApproval(address _owner, uint256 _tokenId) internal
	{
		require(tokenLookup[_tokenId].owner == _owner, "Incorrect PixelCon owner");
		if (tokenApprovals[_tokenId] != address(0)) {
			tokenApprovals[_tokenId] = address(0);
		}
	}

	/**
	 * @notice Add a token ID to the list of a given address
	 * @dev Throws if the receiver address has hit ownership limit or the PixelCon already has an owner
	 * @param _to Address representing the new owner of the given token ID
	 * @param _tokenId ID of the token to be added to the tokens list of the given address
	 */
	function addTokenTo(address _to, uint256 _tokenId) internal
	{
		uint64[] storage ownedList = ownedTokens[_to];
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(ownedList.length < uint256(2 ** 32) - 1, "Max number of PixelCons per owner has been reached");
		require(lookupData.owner == address(0), "PixelCon already has an owner");
		lookupData.owner = _to;

		//update ownedTokens references
		uint ownedListIndex = ownedList.length;
		ownedList.length++;
		lookupData.ownedIndex = uint32(ownedListIndex);
		ownedList[ownedListIndex] = lookupData.tokenIndex;
	}

	/**
	 * @notice Remove a token ID from the list of a given address
	 * @dev Throws if the given address is not indeed the owner of the token
	 * @param _from Address representing the previous owner of the given token ID
	 * @param _tokenId ID of the token to be removed from the tokens list of the given address
	 */
	function removeTokenFrom(address _from, uint256 _tokenId) internal
	{
		uint64[] storage ownedList = ownedTokens[_from];
		TokenLookup storage lookupData = tokenLookup[_tokenId];
		require(lookupData.owner == _from, "From address is incorrect");
		lookupData.owner = address(0);

		//update ownedTokens references
		uint64 replacementTokenIndex = ownedList[ownedList.length - 1];
		delete ownedList[ownedList.length - 1];
		ownedList.length--;
		if (lookupData.ownedIndex < ownedList.length) {
			//we just removed the last token index in the array, but if this wasn't the one to remove, then swap it with the one to remove 
			ownedList[lookupData.ownedIndex] = replacementTokenIndex;
			tokenLookup[pixelcons[replacementTokenIndex].tokenId].ownedIndex = lookupData.ownedIndex;
		}
		lookupData.ownedIndex = 0;
	}

	/**
	 * @notice Invoke `onERC721Received` on a target address (not executed if the target address is not a contract)
	 * @param _from Address representing the previous owner of the given token ID
	 * @param _to Target address that will receive the tokens
	 * @param _tokenId ID of the token to be transferred
	 * @param _data Optional data to send along with the call
	 * @return True if the call correctly returned the expected value
	 */
	function checkAndCallSafeTransfer(address _from, address _to, uint256 _tokenId, bytes _data) internal returns(bool)
	{
		if (!_to.isContract()) return true;

		bytes4 retval = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
		return (retval == ERC721_RECEIVED);
	}
}


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
 * See (https://github.com/OpenZeppelin/openzeppelin-solidity)
 */
contract ERC721Receiver {

	/**
	 * @dev Magic value to be returned upon successful reception of an NFT.
	 * Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
	 * which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
	 */
	bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

	/**
	 * @notice Handle the receipt of an NFT
	 * @dev The ERC721 smart contract calls this function on the recipient
	 * after a `safetransfer`. This function MAY throw to revert and reject the
	 * transfer. Return of other than the magic value MUST result in the
	 * transaction being reverted.
	 * Note: the contract address is always the message sender.
	 * @param _operator The address which called `safeTransferFrom` function
	 * @param _from The address which previously owned the token
	 * @param _tokenId The NFT identifier which is being transferred
	 * @param _data Additional data with no specified format
	 * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	 */
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}


/**
 * @title AddressUtils Library
 * @dev Utility library of inline functions on addresses.
 * See (https://github.com/OpenZeppelin/openzeppelin-solidity)
 */
library AddressUtils {

	/**
	 * Returns whether the target address is a contract
	 * @dev This function will return false if invoked during the constructor of a contract,
	 * as the code is not actually created until after the constructor finishes.
	 * @param _account address of the account to check
	 * @return whether the target address is a contract
	 */
	function isContract(address _account) internal view returns(bool) 
	{
		uint256 size;
		// XXX Currently there is no better way to check if there is a contract in an address
		// than to check the size of the code at that address.
		// See https://ethereum.stackexchange.com/a/14016/36603
		// for more details about how this works.
		// TODO Check this again before the Serenity release, because all addresses will be
		// contracts then.
		assembly { size := extcodesize(_account) }
		return size > 0;
	}
}


/**
 * @title StringUtils Library
 * @dev Utility library of inline functions on strings. 
 * These functions are very expensive and are only intended for web3 calls
 * @author PixelCons
 */
library StringUtils {

	/**
	 * @dev Replaces the given key with the given value in the given string
	 * @param _str String to find and replace in
	 * @param _key Value to search for
	 * @param _value Value to replace key with
	 * @return The replaced string
	 */
	function replace(string _str, string _key, string _value) internal pure returns(string)
	{
		bytes memory bStr = bytes(_str);
		bytes memory bKey = bytes(_key);
		bytes memory bValue = bytes(_value);

		uint index = indexOf(bStr, bKey);
		if (index < bStr.length) {
			bytes memory rStr = new bytes((bStr.length + bValue.length) - bKey.length);

			uint i;
			for (i = 0; i < index; i++) rStr[i] = bStr[i];
			for (i = 0; i < bValue.length; i++) rStr[index + i] = bValue[i];
			for (i = 0; i < bStr.length - (index + bKey.length); i++) rStr[index + bValue.length + i] = bStr[index + bKey.length + i];

			return string(rStr);
		}
		return string(bStr);
	}

	/**
	 * @dev Converts a given number into a string with hex representation
	 * @param _num Number to convert
	 * @param _byteSize Size of the number in bytes
	 * @return The hex representation as string
	 */
	function toHexString(uint256 _num, uint _byteSize) internal pure returns(string)
	{
		bytes memory s = new bytes(_byteSize * 2 + 2);
		s[0] = 0x30;
		s[1] = 0x78;
		for (uint i = 0; i < _byteSize; i++) {
			byte b = byte(uint8(_num / (2 ** (8 * (_byteSize - 1 - i)))));
			byte hi = byte(uint8(b) / 16);
			byte lo = byte(uint8(b) - 16 * uint8(hi));
			s[2 + 2 * i] = char(hi);
			s[3 + 2 * i] = char(lo);
		}
		return string(s);
	}

	/**
	 * @dev Gets the ascii hex character for the given value (0-15)
	 * @param _b Byte to get ascii code for
	 * @return The ascii hex character
	 */
	function char(byte _b) internal pure returns(byte c)
	{
		if (_b < 10) return byte(uint8(_b) + 0x30);
		else return byte(uint8(_b) + 0x57);
	}

	/**
	 * @dev Gets the index of the key string in the given string
	 * @param _str String to search in
	 * @param _key Value to search for
	 * @return The index of the key in the string (string length if not found)
	 */
	function indexOf(bytes _str, bytes _key) internal pure returns(uint)
	{
		for (uint i = 0; i < _str.length - (_key.length - 1); i++) {
			bool matchFound = true;
			for (uint j = 0; j < _key.length; j++) {
				if (_str[i + j] != _key[j]) {
					matchFound = false;
					break;
				}
			}
			if (matchFound) {
				return i;
			}
		}
		return _str.length;
	}
}