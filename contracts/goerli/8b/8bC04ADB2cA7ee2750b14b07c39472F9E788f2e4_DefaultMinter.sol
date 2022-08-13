//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./RandomNumber.sol";

abstract contract AssetInterface {
	function getColours(uint64 pathId, RandomNumber randomNumberController)
		public
		virtual
		returns (uint64[] memory result);

	function getObjectURI() public view virtual returns (string memory) {
		return "";
	}

	function getDefaultName() internal virtual returns (string memory);

	function addColour(uint64 pathId, uint64[] memory result) public virtual {
		revert("colours not implemented");
	}

	function getNextPath() external view virtual returns (uint64);

	function pickPath(
		uint64 currentTokenId,
		RandomNumber randomNumberController
	)
		public
		virtual
		returns (
			uint64,
			uint64[] memory,
			string[] memory,
			uint64[] memory,
			string memory
		);

	function setLastAssets(uint64[] memory assets) public virtual;

	function getNames(uint64 nameCount, RandomNumber randomNumberController)
		public
		virtual
		returns (string[] memory results);

	function getRandomAsset(uint64 pathId, RandomNumber randomNumberController)
		external
		virtual
		returns (uint64[] memory assetsId);

	function getMintData(
		uint64 pathId,
		uint64 tokenId,
		RandomNumber randomNumberController
	) public virtual returns (string memory);

	function addAsset(uint256 rarity) public virtual;

	function getNextName(RandomNumber randomNumberController)
		internal
		virtual
		returns (string memory);

	function getPathGroup(uint64 pathId)
		public
		view
		virtual
		returns (bytes memory, uint64);

	function setNextPathId(uint64 pathId) public virtual;

	function getPathSize(uint64 pathId) public view virtual returns (uint64);

	function getNextPathId(RandomNumber randomNumberController)
		public
		virtual
		returns (uint64);
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";

abstract contract Authentication {
	address public deployer;
	/// @notice for re-entry prevention, keeps track of a methods execution count
	uint256 private executionCount;

	mapping(address => bool) internal approved;

	constructor() {
		deployer = msg.sender;
		approved[msg.sender] = true;
		executionCount = 0;
	}

	/// @notice Limits execution of a method to once in the given context.
	/// @dev prevents re-entry attack
	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

	modifier onlyDeployer() {
		if (msg.sender != deployer) revert("not deployer");
		_;
	}

	modifier onlyApproved() {
		if (approved[msg.sender] == false) revert("not approved");
		_;
	}

	function togglePrivilages(address addr) public onlyDeployer {
		approved[addr] = !approved[addr];
	}

	function transferOwnership(address addr) public onlyDeployer {
		deployer = addr;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

//this is implemented by every contract in our system
import "./InfinityMintUtil.sol";
import "./InfinityMintValues.sol";

abstract contract InfinityMintObject {
	/// @notice The main InfinityMint object, TODO: Work out a way for this to easily be modified
	struct ReturnObject {
		uint64 pathId;
		uint64 pathSize;
		uint64 currentTokenId;
		address owner;
		address wallet;
		address stickers;
		uint64[] colours;
		string mintData;
		uint64[] assets;
		string[] names;
	}

	/// @notice Creates a new struct from arguments
	/// @dev Stickers are not set through this, structs cannot be made with sticker contracts already set and have to be set manually
	/// @param currentTokenId the tokenId,
	/// @param pathId the infinity mint paths id
	/// @param pathSize the size of the path (only for vectors)
	/// @param assets the assets which make up the token
	/// @param names the names of the token, its just the name but split by the splaces.
	/// @param colours decimal colours which will be convered to hexadecimal colours
	/// @param mintData variable dynamic field which is passed to ERC721 Implementor contracts and used in a lot of dynamic stuff
	/// @param _sender aka the owner of the token
	/// @param wallet the wallet location
	function createReturnObject(
		uint64 currentTokenId,
		uint64 pathId,
		uint64 pathSize,
		uint64[] memory assets,
		string[] memory names,
		uint64[] memory colours,
		string memory mintData,
		address _sender,
		address wallet
	) internal pure returns (ReturnObject memory) {
		return
			ReturnObject(
				pathId,
				pathSize,
				currentTokenId,
				_sender, //the sender aka owner
				wallet, //the address of the wallet contract
				address(0x0), //stores stickers
				colours,
				mintData,
				assets,
				names
			);
	}

	/// @notice basically unpacks a return object into bytes.
	function encode(ReturnObject memory data)
		internal
		pure
		returns (bytes memory)
	{
		return
			abi.encode(
				data.pathId,
				data.pathSize,
				data.currentTokenId,
				data.owner,
				data.wallet,
				data.stickers,
				abi.encode(data.colours),
				bytes(data.mintData),
				data.assets,
				data.names
			);
	}

	/// @notice Copied behavours of the open zeppelin content due to prevent msg.sender rewrite through assembly
	function sender() internal view virtual returns (address) {
		return msg.sender;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";
import "./Authentication.sol";

/// @title InfinityMint storage controller
/// @author Llydia Cross
/// @notice Stores the outcomes of the mint process and previews and also unlock keys
/// @dev Attached to to an InfinityMint
contract InfinityMintStorage is Authentication, InfinityMintObject {
	/// @notice previews
	mapping(address => bytes[]) public previews;

	/// @notice all of the token data
	mapping(uint64 => ReturnObject) private tokens;

	/// @notice private mapping holding a list of tokens for owned by the address for quick look up
	mapping(address => uint64[]) private registeredTokens;

	/// @notice private mapping of the private keys associated with each token owner.
	mapping(address => mapping(uint256 => uint256[])) private keys;

	/// @notice returns true if the address is preview blocked and unable to receive more previews
	function isPreviewBlocked(address addr) public view returns (bool) {
		return previews[addr].length != 0;
	}

	/// @notice makes a new key pair for locking/unlocking tokens
	/// @dev keys are prime number based, first get get a random selection of primes and then square root them a random amount of times to generate the public key
	/// @param addr the address to generate a new key pair for
	function newKey(
		address addr,
		uint256 powerOf,
		uint256[] memory primes
	) public onlyApproved {
		//add private primes to the key storage
		keys[addr][0] = primes;

		//add to the keys storage
		keys[addr][1] = getNewPubKey(primes.length, primes, powerOf);

		uint256[] memory temp = new uint256[](1);
		temp[0] = uint256(block.timestamp) + (60 * 2); //dont allow get after 2 minutes

		//add it to the keys storage
		keys[addr][2] = temp;
	}

	/// @notice returns true if the address has a private key setup
	/// @dev Can only be called by approved addresses to the storage
	/// @param addr the address to get the key for
	/// @param index the part of the key, 0 = private key, 1 = public key, 2 = withholdAfter
	function getKey(address addr, uint256 index)
		external
		view
		onlyApproved
		returns (uint256[] memory)
	{
		return keys[addr][index];
	}

	/// @notice returns true if the address has a private key setup
	/// @dev Can only be called by approved addresses to the storage
	/// @param addr the address to check has a key
	function hasKey(address addr) external view onlyApproved returns (bool) {
		return keys[addr][0].length != 0;
	}

	/// @notice Destroys a unlock/lock key associated with the senders address
	/// @dev will kick off the withholdAfter timezone you can view the token, so be sure to have the user call getPublicKey right after calling this, this is put inside of keys[addr][2]
	/// @param addr the address to destroy the key of
	/// @param powerOf the amount of times to power the primes
	/// @param primes the list of primes
	function destroyKey(
		address addr,
		uint256 powerOf,
		uint256[] memory primes
	) public onlyApproved {
		require(keys[addr][0].length != 0, "has no private key");
		newKey(addr, powerOf, primes);
	}

	/// @notice returns address of the owner of this token
	/// @param tokenId the tokenId to get the owner of
	function getOwner(uint64 tokenId) public view returns (address) {
		return tokens[tokenId].owner;
	}

	/// @notice returns an integer array containing the token ids owned by the owner address
	/// @param owner the owner to look for
	function getAll(address owner) public view returns (uint64[] memory) {
		return registeredTokens[owner];
	}

	/// @notice pushes the tokenId to the registeredTokens array for the given address
	/// @param owner the owner to add the token too
	/// @param tokenId the tokenId to add
	function addToRegisteredTokens(address owner, uint64 tokenId)
		public
		onlyApproved
	{
		registeredTokens[owner].push(tokenId);
	}

	/// @notice gets a token at by the owner at a specific index (relative to their tokens
	/// @dev Tokens are indexable instead by their current positon inside of the owner wallets collection, returns a tokenId
	/// @param owner the owner to look up
	/// @param index the index to fetch
	function getAtIndex(address owner, uint256 index)
		public
		view
		returns (uint64 tokenId)
	{
		require(registeredTokens[owner].length < index, "out of bounds");
		return registeredTokens[owner][index];
	}

	/// @notice Gets the amount of tokens the owner has, same as balanceOf on main ERC721
	/// @dev Tokens are indexable instead by their current positon inside of the owner wallets collection, returns a tokenId
	/// @param owner the owner to get the length of
	function getCount(address owner) public view returns (uint256) {
		return registeredTokens[owner].length;
	}

	/// @notice returns a token
	/// @dev returns a struct not bytes, use getEncoded to return bytes instead.
	/// @param tokenId the tokenId to get
	function get(uint64 tokenId) public view returns (ReturnObject memory) {
		if (tokens[tokenId].owner == address(0x0)) revert();

		return tokens[tokenId];
	}

	/// @notice returns a token
	/// @dev returns bytes not a struct, use get to get a struct instead
	/// @param tokenId the tokenId to get
	function getEncoded(uint64 tokenId) public view returns (bytes memory) {
		if (tokens[tokenId].owner == address(0x0)) revert();

		return encode(tokens[tokenId]);
	}

	function transfer(address to, uint64 tokenId) public onlyApproved {
		ReturnObject memory temp = get(tokenId);
		address oldOwner = (temp.owner);

		//change the struct to equal to the new address holder
		set(
			tokenId,
			ReturnObject(
				temp.pathId,
				temp.pathSize,
				temp.currentTokenId,
				to,
				temp.wallet,
				temp.stickers,
				temp.colours,
				temp.mintData,
				temp.assets,
				temp.names
			)
		);

		//delete from the old owners registerTokens array
		deleteInArray(oldOwner, tokenId);
		registeredTokens[to].push(tokenId); //register the new owner
	}

	function set(uint64 tokenId, ReturnObject memory data) public onlyApproved {
		require(data.owner != address(0x0), "null owner");

		//if its a new token set
		if (tokens[tokenId].owner == address(0x0)) {
			addToRegisteredTokens(data.owner, tokenId);
			//delete previews for the address
			deletePreview(data.owner);
		}

		tokens[tokenId] = data;
	}

	function setRaw(uint64 tokenId, bytes memory _data) public onlyApproved {
		set(tokenId, abi.decode(_data, (ReturnObject)));
	}

	function setPreviews(address owner, ReturnObject[] memory data)
		public
		onlyApproved
	{
		bytes[] memory temp = new bytes[](data.length);
		for (uint256 i = 0; i < temp.length; i++) temp[i] = abi.encode(data[i]);

		previews[owner] = temp;
	}

	function getPreview(address owner)
		public
		view
		onlyApproved
		returns (ReturnObject[] memory)
	{
		require(previews[owner].length != 0);
		ReturnObject[] memory temp = new ReturnObject[](previews[owner].length);
		for (uint256 i = 0; i < previews[owner].length; i++)
			temp[i] = abi.decode(previews[owner][i], (ReturnObject));

		return temp;
	}

	function deletePreview(address owner) public onlyApproved {
		delete previews[owner];
	}

	function existsInArray(address sender, uint64 tokenId)
		private
		view
		returns (bool)
	{
		if (registeredTokens[sender].length == 0) return false;

		for (uint256 i = 0; i < registeredTokens[sender].length; i++) {
			if (registeredTokens[sender][i] == tokenId) return true;
		}

		return false;
	}

	function deleteInArray(address sender, uint64 tokenId) private {
		if (registeredTokens[sender].length - 1 <= 0)
			delete registeredTokens[sender];

		uint64 index = 0;
		uint64[] memory newArray = new uint64[](
			registeredTokens[sender].length - 1
		);

		for (uint256 i = 0; i < registeredTokens[sender].length; i++) {
			if (registeredTokens[sender][i] == tokenId) continue;

			newArray[index++] = registeredTokens[sender][i];
		}

		registeredTokens[sender] = newArray;
	}

	/// @notice Returns a new public key.
	/// @dev See newKey inside this same contract for a more detailed description.
	/// @param length the length of the new key to make.
	/// @param privateKey the private key for this user
	/// @param powerOf amount of times to square the prime
	function getNewPubKey(
		uint256 length,
		uint256[] memory privateKey,
		uint256 powerOf
	) private pure returns (uint256[] memory _newKey) {
		_newKey = new uint256[](length);
		if (powerOf <= 0) powerOf = 2;

		for (uint256 i = 0; i < _newKey.length; i++) {
			_newKey[i] = InfinityMintUtil.square(privateKey[i], powerOf);
		}
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

library InfinityMintUtil {
	function toString(uint256 _i)
		internal
		pure
		returns (string memory _uintAsString)
	{
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	function square(uint256 num, uint256 amount)
		internal
		pure
		returns (uint256)
	{
		if (amount <= 1) return (num * num);

		for (uint256 i = 0; i < amount; i++) num = (num * num);
		return num;
	}

	function getRSV(bytes memory signature)
		internal
		pure
		returns (
			bytes32 r,
			bytes32 s,
			uint8 v
		)
	{
		require(signature.length == 65, "invalid length");
		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := byte(0, mload(add(signature, 96)))
		}
	}

	//checks if two strings (or bytes) are equal
	function isEqual(bytes memory s1, bytes memory s2)
		internal
		pure
		returns (bool)
	{
		bytes memory b1 = bytes(s1);
		bytes memory b2 = bytes(s2);
		uint256 l1 = b1.length;
		if (l1 != b2.length) return false;
		for (uint256 i = 0; i < l1; i++) {
			//check each byte
			if (b1[i] != b2[i]) return false;
		}
		return true;
	}

	function unpackSticker(bytes memory sticker)
		internal
		pure
		returns (
			uint64 tokenId,
			string memory checkSum,
			string memory object,
			address owner
		)
	{
		return abi.decode(sticker, (uint64, string, string, address));
	}

	function unpackKazoo(bytes memory preview)
		internal
		pure
		returns (
			uint64 pathId,
			uint64 pathSize,
			uint64 tokenId,
			address owner,
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory data,
			uint64[] memory assets,
			string[] memory names
		)
	{
		return
			abi.decode(
				preview,
				(
					uint64,
					uint64,
					uint64,
					address,
					address,
					address,
					bytes,
					bytes,
					uint64[],
					string[]
				)
			);
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

contract InfinityMintValues {
	mapping(string => uint256) private values;
	mapping(string => bool) private booleanValues;
	mapping(string => bool) private registeredValues;

	address deployer;

	constructor() {
		deployer = msg.sender;
	}

	modifier onlyDeployer() {
		if (msg.sender != deployer) revert();
		_;
	}

	function setValue(string memory key, uint256 value) public onlyDeployer {
		values[key] = value;
		registeredValues[key] = true;
	}

	function setupValues(
		string[] memory keys,
		uint256[] memory _values,
		string[] memory booleanKeys,
		bool[] memory _booleanValues
	) public onlyDeployer {
		require(keys.length == _values.length);
		require(booleanKeys.length == _booleanValues.length);
		for (uint256 i = 0; i < keys.length; i++) {
			setValue(keys[i], _values[i]);
		}

		for (uint256 i = 0; i < booleanKeys.length; i++) {
			setBooleanValue(booleanKeys[i], _booleanValues[i]);
		}
	}

	function setBooleanValue(string memory key, bool value)
		public
		onlyDeployer
	{
		booleanValues[key] = value;
		registeredValues[key] = true;
	}

	function isTrue(string memory key) external view returns (bool) {
		return booleanValues[key];
	}

	function getValue(string memory key) external view returns (uint256) {
		if (!registeredValues[key]) revert("Invalid Value");

		return values[key];
	}

	function tryGetValue(string memory key) external view returns (uint256) {
		if (!registeredValues[key]) return 1;

		return values[key];
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Authentication.sol";
import "./InfinityMintStorage.sol";
import "./AssetInterface.sol";
import "./RandomNumber.sol";
import "./InfinityMintObject.sol";

abstract contract MinterInterface is Authentication {
	InfinityMintValues valuesController;
	InfinityMintStorage storageController;
	AssetInterface assetController;
	RandomNumber randomNumberController;

	/*
	 */
	constructor(
		address valuesContract,
		address storageContract,
		address assetContract,
		address randomNumberContract
	) {
		valuesController = InfinityMintValues(valuesContract);
		storageController = InfinityMintStorage(storageContract);
		assetController = AssetInterface(assetContract);
		randomNumberController = RandomNumber(randomNumberContract);
	}

	function mint(uint64 currentTokenId, address sender)
		public
		virtual
		returns (InfinityMintObject.ReturnObject memory);

	/**
		Fast Mint used in mintAll
	 */
	function implicitMint(
		uint64 currentTokenId,
		uint64 pathId,
		uint64 pathSize,
		uint64[] memory colours,
		string memory mintData,
		address sender,
		uint64[] memory assets
	) external virtual returns (InfinityMintObject.ReturnObject memory);

	/**

     */
	function getPreview(uint64 currentTokenId, address sender)
		external
		virtual
		returns (InfinityMintObject.ReturnObject[] memory);

	function selectiveMint(
		uint64 currentTokenId,
		uint64 pathId,
		address sender
	) external virtual returns (InfinityMintObject.ReturnObject memory);

	/*

    */
	function mintPreview(
		uint64 index,
		uint64 currentTokenId,
		address sender
	) external virtual returns (InfinityMintObject.ReturnObject memory);
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintValues.sol";

abstract contract RandomNumber {
	uint256 public randomnessFactor;
	bool public hasDeployed = false;
	uint256 public salt = 1;

	InfinityMintValues valuesController;

	modifier hasNotSetup() {
		if (hasDeployed) revert();
		_;
		hasDeployed = true;
	}

	constructor(address valuesContract) {
		valuesController = InfinityMintValues(valuesContract);
		randomnessFactor = valuesController.getValue("randomessFactor");
	}

	function getNumber() external returns (uint256) {
		if (salt + 1 > 2147483647) salt = 0;

		return
			returnNumber(valuesController.getValue("maxRandomNumber"), salt++);
	}

	function getMaxNumber(uint256 maxNumber) external returns (uint256) {
		if (salt + 1 > 2147483647) salt = 0;

		return returnNumber(maxNumber, salt++);
	}

	function sqrt(uint256 x) external pure returns (uint256 y) {
		uint256 z = (x + 1) / 2;
		y = x;
		while (z < y) {
			y = z;
			z = (x / z + z) / 2;
		}
	}

	function getRandomPrimes(uint256 _count)
		external
		virtual
		returns (uint256[] memory);

	//called upon main deployment of the main kazooKid contract, can only be called once!
	function setup(
		address infinityMint,
		address infinityMintStorage,
		address infinityMintAsset
	) public virtual hasNotSetup {}

	function returnNumber(uint256 maxNumber, uint256 _salt)
		public
		view
		virtual
		returns (uint256)
	{
		if (maxNumber <= 0) maxNumber = 1;

		return (_salt + 3) % maxNumber;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./../MinterInterface.sol";
import "./../InfinityMintObject.sol";

contract DefaultMinter is MinterInterface, InfinityMintObject {
	/*
	 */
	constructor(
		address valuesContract,
		address storageContract,
		address assetContract,
		address randomNumberContract
	)
		MinterInterface(
			valuesContract,
			storageContract,
			assetContract,
			randomNumberContract
		)
	{}

	function mintPreview(
		uint64 index,
		uint64 currentTokenId,
		address sender
	)
		external
		view
		virtual
		override
		onlyApproved
		returns (ReturnObject memory)
	{
		ReturnObject[] memory tempArray = storageController.getPreview(sender);

		if (index >= tempArray.length || index < 0) revert("bad index");

		ReturnObject memory temp = tempArray[index];

		//check the owner to see if its the same
		if (temp.owner != sender) revert();
		if (temp.currentTokenId != index) revert();

		return
			createReturnObject(
				currentTokenId,
				temp.pathId,
				temp.pathSize,
				temp.assets,
				temp.names,
				temp.colours,
				temp.mintData,
				temp.owner,
				temp.wallet
			);
	}

	/**
		Fast Mint used in mintAll
	 */
	function implicitMint(
		uint64 currentTokenId,
		uint64 pathId,
		uint64 pathSize,
		uint64[] memory colours,
		string memory mintData,
		address sender,
		uint64[] memory assets
	) external virtual override onlyApproved returns (ReturnObject memory) {
		//sets the next (is the current) pathgroup to this pathId, this is so the asset controller
		//retruns correct assets for this pathId such as the name + assets
		assetController.setNextPathId(pathId);
		assetController.setLastAssets(assets); //set last assets

		//get the name of this
		string[] memory names = assetController.getNames(
			uint64(
				randomNumberController.getMaxNumber(
					valuesController.tryGetValue("nameCount")
				)
			),
			randomNumberController
		);

		return
			createReturnObject(
				currentTokenId,
				pathId,
				pathSize,
				assets,
				names,
				colours,
				mintData,
				sender,
				address(0x0)
			);
	}

	/**
	 */
	function selectiveMint(
		uint64 currentTokenId,
		uint64 pathId,
		address sender
	) external virtual override onlyApproved returns (ReturnObject memory) {}

	/**

     */
	function getPreview(uint64 currentTokenId, address sender)
		external
		virtual
		override
		onlyApproved
		returns (ReturnObject[] memory previews)
	{
		previews = new ReturnObject[](
			valuesController.tryGetValue("previewCount")
		);

		uint64 pathSize;
		string[] memory names;
		uint64[] memory assets;
		uint64[] memory colours;
		string memory mintData;

		for (
			uint64 i = 0;
			i < valuesController.tryGetValue("previewCount");
			i++
		) {
			(pathSize, assets, names, colours, mintData) = assetController
				.pickPath(currentTokenId, randomNumberController);

			previews[i] = createReturnObject(
				i,
				assetController.getNextPath(),
				pathSize,
				assets,
				names,
				colours,
				mintData,
				sender,
				address(0x0)
			);
		}

		return previews;
	}

	/*

    */
	function mint(uint64 currentTokenId, address sender)
		public
		virtual
		override
		onlyApproved
		returns (ReturnObject memory)
	{
		uint64 pathSize;
		string[] memory names;
		uint64[] memory assets;
		uint64[] memory colours;
		string memory mintData;

		(pathSize, assets, names, colours, mintData) = assetController.pickPath(
			currentTokenId,
			randomNumberController
		);

		return
			createReturnObject(
				currentTokenId,
				assetController.getNextPath(),
				pathSize,
				assets,
				names,
				colours,
				mintData,
				sender,
				address(0x0)
			);
	}
}