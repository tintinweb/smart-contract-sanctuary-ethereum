//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./RandomNumber.sol";

abstract contract AssetInterface {
	function getColours(
		uint64 pathSize,
		uint64 pathId,
		RandomNumber randomNumberController
	) public virtual returns (uint64[] memory result);

	function getObjectURI() public view virtual returns (string memory) {
		return "";
	}

	function getDefaultName() public virtual returns (string memory);

	function addColour(uint64 pathId, uint64[] memory result) public virtual {}

	function getNames(uint64 nameCount, RandomNumber randomNumberController)
		public
		virtual
		returns (string[] memory results);

	function getRandomAsset(uint64 pathId, RandomNumber randomNumberController)
		public
		virtual
		returns (uint64[] memory assetsId);

	function getMintData(
		uint64 pathId,
		uint64 tokenId,
		RandomNumber randomNumberController
	) public virtual returns (string memory);

	function addAsset(uint256 rarity) public virtual;

	function getNextName(RandomNumber randomNumberController)
		public
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
	address deployer;

	mapping(address => bool) internal approved;

	constructor() {
		deployer = msg.sender;
		approved[msg.sender] = true;
	}

	modifier onlyDeployer() {
		if (msg.sender != deployer) revert();
		_;
	}

	modifier onlyApproved() {
		if (approved[msg.sender] == false) revert();
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
	) public pure returns (ReturnObject memory) {
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

	function _encode(ReturnObject memory data)
		public
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

	//does the same as open zepps contract
	function sender() public view virtual returns (address) {
		return msg.sender;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";

//written by Llydia Cross
contract InfinityMintStorage is InfinityMintObject {
	address private deployer;
	mapping(uint64 => ReturnObject) private previews;
	mapping(uint64 => bytes) private cards;
	mapping(uint64 => ReturnObject) private kazoos;
	mapping(uint64 => address) private registeredKazoos;
	mapping(uint64 => address) private registeredPreviews;
	//public stuff
	mapping(address => bool) public authenticated;
	mapping(address => bool) public previewBlocked;
	mapping(address => uint256) public firstHeldAt; //first held a token at this id ( for fast look up)

	constructor() {
		deployer = sender();
		authenticated[deployer] = true;
	}

	modifier onlyAuthenticated() {
		if (authenticated[sender()] == false) revert();
		_;
	}

	modifier onlyDeployer() {
		if (deployer != sender()) revert();
		_;
	}

	function registerPreview(uint64 previewId, address owner)
		public
		onlyAuthenticated
	{
		if (registeredPreviews[previewId] != address(0x0))
			revert("Already Registered");

		registeredPreviews[previewId] = owner;
	}

	function registerKazoo(uint64 kazooId, address owner)
		public
		onlyAuthenticated
	{
		if (registeredKazoos[kazooId] != address(0x0)) revert();

		if (kazooId < firstHeldAt[owner]) firstHeldAt[owner] = kazooId;

		registeredKazoos[kazooId] = owner;
	}

	function transferKazoo(address to, uint64 kazooId)
		public
		onlyAuthenticated
	{
		if (kazooId < firstHeldAt[to]) firstHeldAt[to] = kazooId;

		ReturnObject memory temp = get(kazooId);
		set(
			kazooId,
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
		registeredKazoos[kazooId] = to;
	}

	function isPreviewBlocked(address addr) public view returns (bool) {
		return previewBlocked[addr] == true;
	}

	function wipePreviews(address addr, uint64 currentPreviewId) public {
		uint64[] memory rPreviews = allPreviews(addr, currentPreviewId);

		for (uint256 i = 0; i < rPreviews.length; i++) {
			delete registeredPreviews[rPreviews[i]];
			delete previews[rPreviews[i]];
		}
	}

	function allPreviews(address owner, uint64 currentPreviewId)
		public
		view
		returns (uint64[] memory rPreviews)
	{
		if (owner == address(0x0)) revert();

		if (currentPreviewId != 0) {
			uint64 previewId = 0;
			uint64 count = 0;

			//count how many we have
			while (previewId < currentPreviewId) {
				if (owner == getPreviewOwner(previewId)) count++;
				previewId++;
			}

			//if we did infact find any
			if (count != 0) {
				//create a new array for the ids with the count of that
				rPreviews = new uint64[](count);
				//reset back to zero
				count = 0;
				previewId = 0;
				//do it again, this time populating the array.
				while (previewId < currentPreviewId) {
					if (owner == getPreviewOwner(previewId))
						rPreviews[count++] = previewId;

					previewId++;
				}
			}
		}
	}

	function getOwner(uint64 kazooId) public view returns (address) {
		return registeredKazoos[kazooId];
	}

	function getPreviewOwner(uint64 previewId) public view returns (address) {
		return registeredPreviews[previewId];
	}

	function setAuthenticationStatus(address sender, bool value)
		public
		onlyDeployer
	{
		authenticated[sender] = value;
	}

	function set(uint64 kazooId, ReturnObject memory data)
		public
		onlyAuthenticated
	{
		kazoos[kazooId] = data;
	}

	function setPreviewBlock(address sender, bool value)
		public
		onlyAuthenticated
	{
		previewBlocked[sender] = value;
	}

	function setPreview(uint64 previewId, ReturnObject memory data)
		public
		onlyAuthenticated
	{
		previews[previewId] = data;
	}

	function getPreview(uint64 previewId)
		public
		view
		onlyAuthenticated
		returns (ReturnObject memory)
	{
		if (previews[previewId].owner == address(0x0)) revert();

		return previews[previewId];
	}

	function deletePreview(uint64 previewId) public onlyAuthenticated {
		if (previews[previewId].owner == address(0x0)) revert();

		delete previews[previewId];
	}

	function get(uint64 kazooId) public view returns (ReturnObject memory) {
		if (kazoos[kazooId].owner == address(0x0)) revert();

		return kazoos[kazooId];
	}

	function getEncoded(uint64 kazooId) public view returns (bytes memory) {
		if (kazoos[kazooId].owner == address(0x0)) revert();

		return _encode(kazoos[kazooId]);
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

	// https://solidity-by-example.org/signature/
	function getRSV(bytes memory signature)
		public
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
			uint64 kazooId,
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

	function isTrue(string memory key) public view returns (bool) {
		return booleanValues[key];
	}

	function getValue(string memory key) public view returns (uint256) {
		if (!registeredValues[key]) revert("Invalid Value");

		return values[key];
	}

	function tryGetValue(string memory key) public view returns (uint256) {
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
		address sender
	) external virtual returns (InfinityMintObject.ReturnObject memory);

	/**

     */
	function getPreview(
		uint64 currentTokenId,
		uint64 currentPreviewId,
		address sender
	) external virtual returns (InfinityMintObject.ReturnObject[] memory);

	function selectiveMint(
		uint64 currentTokenId,
		uint64 pathId,
		address sender
	) external virtual returns (InfinityMintObject.ReturnObject memory);

	/*

    */
	function mintPreview(
		uint64 previewId,
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

	function getNumber() public returns (uint256) {
		return returnNumber(valuesController.getValue("maxRandomNumber"));
	}

	function getMaxNumber(uint256 maxNumber) public returns (uint256) {
		return returnNumber(maxNumber);
	}

	//called upon main deployment of the main kazooKid contract, can only be called once!
	function setup(
		address infinityMint,
		address infinityMintStorage,
		address infinityMintAsset
	) public virtual hasNotSetup {}

	function returnNumber(uint256 maxNumber)
		internal
		virtual
		returns (uint256)
	{}
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
		uint64 previewId,
		uint64 currentTokenId,
		address sender
	) external override onlyApproved returns (ReturnObject memory) {
		ReturnObject memory temp = storageController.getPreview(previewId);

		//check the owner to see if its the same
		if (temp.owner != sender) revert();
		if (temp.currentTokenId != previewId) revert();

		return
			createReturnObject(
				temp.currentTokenId,
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
		address sender
	) external override onlyApproved returns (ReturnObject memory) {
		//sets the next (is the current) pathgroup to this pathId, this is so the asset controller
		//retruns correct assets for this pathId such as the name + assets
		assetController.setNextPathId(pathId);
		uint64[] memory assets = assetController.getRandomAsset(
			pathId,
			randomNumberController
		);
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
	) external override onlyApproved returns (ReturnObject memory) {}

	/**

     */
	function getPreview(
		uint64 currentTokenId,
		uint64 currentPreviewId,
		address sender
	) external override onlyApproved returns (ReturnObject[] memory previews) {
		previews = new ReturnObject[](
			valuesController.tryGetValue("previewCount")
		);

		for (
			uint64 i = 0;
			i < valuesController.tryGetValue("previewCount");
			i++
		) {
			uint64 pathId = assetController.getNextPathId(
				randomNumberController
			);

			previews[i] = createReturnObject(
				currentPreviewId,
				pathId,
				assetController.getPathSize(pathId),
				assetController.getRandomAsset(pathId, randomNumberController),
				assetController.getNames(
					uint64(
						randomNumberController.getMaxNumber(
							valuesController.tryGetValue("nameCount")
						)
					),
					randomNumberController
				),
				assetController.getColours(
					assetController.getPathSize(pathId),
					pathId,
					randomNumberController
				),
				assetController.getMintData(
					pathId,
					currentTokenId,
					randomNumberController
				),
				sender,
				address(0x0)
			);

			storageController.setPreview(currentPreviewId, previews[i]);
			storageController.registerPreview(currentPreviewId, sender);
			currentPreviewId++;
		}

		return previews;
	}

	/*

    */
	function mint(uint64 currentTokenId, address sender)
		public
		override
		onlyApproved
		returns (ReturnObject memory)
	{
		uint64 pathId = assetController.getNextPathId(randomNumberController);
		uint64 pathSize = assetController.getPathSize(pathId);
		//how many names we should generate
		uint64 nameCount = uint64(
			randomNumberController.getMaxNumber(
				valuesController.tryGetValue("nameCount")
			)
		);

		if (nameCount <= 0) nameCount++; //make it 1

		return
			createReturnObject(
				currentTokenId,
				pathId,
				pathSize,
				assetController.getRandomAsset(pathId, randomNumberController),
				assetController.getNames(nameCount, randomNumberController),
				assetController.getColours(
					pathSize,
					pathId,
					randomNumberController
				),
				assetController.getMintData(
					pathId,
					currentTokenId,
					randomNumberController
				),
				sender,
				address(0x0)
			);
	}
}