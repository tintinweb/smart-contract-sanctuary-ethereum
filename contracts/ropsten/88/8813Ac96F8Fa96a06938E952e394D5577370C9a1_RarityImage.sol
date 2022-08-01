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

import "./AssetInterface.sol";
import "./Authentication.sol";

abstract contract InfinityMintAsset is AssetInterface, Authentication {
	mapping(uint256 => bool) internal disabledPaths;
	mapping(uint256 => uint256[]) public pathSections;

	string internal tokenName = "asset";

	InfinityMintValues valuesController;

	//paths are a complete
	bytes[] internal kazooPaths;
	uint256 internal assets;
	uint256 internal safeDefaultReturnPath;
	uint256[] internal assetRarity;
	uint64[] internal pathSizes;
	uint256[][] internal assetsSections;
	string[] internal names;
	uint64[] internal lastAssets;
	string public assetsType = "default";
	uint64 public nextPath;
	string public objectURI;
	bool private flatSections = false;

	constructor(address valuesContract) {
		valuesController = InfinityMintValues(valuesContract);
		assetRarity.push(0); //so assets start at 1 not zero so zero can be treat as a
	}

	function getObjectURI() public view override returns (string memory) {
		return objectURI;
	}

	function setNames(string[] memory newNames) public onlyApproved {
		names = newNames;
	}

	function combineNames(string[] memory newNames) public onlyApproved {
		require(newNames.length < 100);

		for (uint256 i = 0; i < newNames.length; i++) {
			names.push(newNames[i]);
		}
	}

	function addName(string memory name) public onlyApproved {
		names.push(name);
	}

	function setObjectURI(string memory json) public onlyApproved {
		objectURI = json;
	}

	function setNextPathId(uint64 pathId) public virtual override onlyApproved {
		nextPath = pathId;
	}

	function getPathGroup(uint64 pathId)
		public
		view
		virtual
		override
		returns (bytes memory, uint64)
	{
		if (InfinityMintUtil.isEqual(kazooPaths[pathId], ""))
			revert("Invalid Path");

		return abi.decode(kazooPaths[pathId], (bytes, uint64));
	}

	function setPathSize(uint64 pathId, uint64 pathSize) public onlyApproved {
		pathSizes[pathId] = pathSize;
	}

	function getPathSize(uint64 pathId) public view override returns (uint64) {
		return pathSizes[pathId];
	}

	function getNextPathId(RandomNumber randomNumberController)
		public
		virtual
		override
		returns (uint64)
	{
		uint256 result = randomNumberController.getMaxNumber(kazooPaths.length);

		//path is disabled
		if (result >= kazooPaths.length) result = (safeDefaultReturnPath);

		//count up until a non disabled path is found
		while (disabledPaths[result]) {
			if (result + 1 >= kazooPaths.length)
				result = (safeDefaultReturnPath);
			result++;
		}

		return uint64(result);
	}

	function getRandomNameKey(RandomNumber randomNumberController)
		internal
		returns (uint64)
	{
		//pick an asset
		uint256 result = randomNumberController.getMaxNumber(names.length);
		if (result < names.length) return uint64(result);

		return 0;
	}

	function getNextName(RandomNumber randomNumberController)
		public
		virtual
		override
		returns (string memory)
	{
		if (names.length == 0) return "null";

		return names[getRandomNameKey(randomNumberController)];
	}

	function getNames(uint64 nameCount, RandomNumber randomNumberController)
		public
		virtual
		override
		returns (string[] memory results)
	{
		if (
			valuesController.isTrue("matchedMode") ||
			valuesController.isTrue("incrementalMode")
		) {
			results = new string[](2);

			if (names.length == 0) results[0] = "null";
			else if (nextPath < names.length) results[0] = names[nextPath];
			else results[0] = names[0];

			results[1] = getDefaultName();
		} else if (valuesController.isTrue("useAssetsForName")) {
			//TODO: use lastAssets to get the name of each asset making up the name
		} else {
			if (nameCount <= 0) {
				results = new string[](1);
				results[0] = getDefaultName();
				return results;
			}

			results = new string[](nameCount + 1);

			for (uint64 i = 0; i < nameCount; i++) {
				results[i] = getNextName(randomNumberController);
			}
			results[nameCount] = getDefaultName();
		}
	}

	function getMintData(
		uint64 pathId,
		uint64 tokenId,
		RandomNumber randomNumberController
	) public virtual override returns (string memory) {
		return "{}"; //returns a blank json array
	}

	function getDefaultName() public virtual override returns (string memory) {
		return tokenName;
	}

	function getRandomAsset(uint64 pathId, RandomNumber randomNumberController)
		public
		virtual
		override
		returns (uint64[] memory assetsId)
	{
		assetsId = new uint64[](0);

		if (assets == 0) {
			lastAssets = assetsId;
			return assetsId;
		}

		uint256[] memory sections;
		if (flatSections) sections = pathSections[0];
		else sections = pathSections[pathId];

		uint256 indexPosition = 0;
		if (sections.length == 0) {
			lastAssets = assetsId;
			return assetsId;
		} else {
			assetsId = new uint64[](sections.length);
			for (uint256 i = 0; i < sections.length; i++) {
				uint256[] memory section = assetsSections[sections[i]];

				if (section.length == 0) {
					assetsId[indexPosition++] = 0;
					continue;
				}

				uint256[] memory selectedPaths = new uint256[](section.length);
				//repeat filling array with found values
				uint256 count = 0;
				for (uint256 index = 0; index < section.length; index++) {
					if (count == section.length) break;
					if (section[index] == 0) continue;
					uint256 rarity = 0;

					if (assetRarity.length > section[index])
						rarity = assetRarity[section[index]];

					if (
						(rarity > randomNumberController.getMaxNumber(100) ||
							rarity == 100)
					) selectedPaths[count++] = section[index];
				}

				//pick an asset
				uint256 result = 0;

				if (count >= 2)
					result = randomNumberController.getMaxNumber(count);

				if (count <= 1)
					assetsId[indexPosition++] = uint64(selectedPaths[0]);
				else if (selectedPaths.length > result)
					assetsId[indexPosition++] = uint64(selectedPaths[result]);
				else assetsId[indexPosition++] = 0;
			}
		}

		lastAssets = assetsId;
	}

	function setSectionAssets(uint64 sectionId, uint256[] memory _assets)
		public
		onlyDeployer
	{
		assetsSections[sectionId] = _assets;
	}

	function pushSectionAssets(uint256[] memory _assets) public onlyDeployer {
		assetsSections.push(_assets);
	}

	function flatPathSections(uint64[] memory pathIds) public onlyDeployer {
		pathSections[0] = pathIds;
		flatSections = true;
	}

	function setPathSections(
		uint64[] memory pathIds,
		uint256[][] memory _sections
	) public onlyDeployer {
		require(pathIds.length == _sections.length);

		for (uint256 i = 0; i < pathIds.length; i++) {
			pathSections[pathIds[i]] = _sections[i];
		}
	}

	function addAssets(uint256[] memory rarities) public onlyDeployer {
		for (uint256 i = 0; i < rarities.length; i++) {
			if (rarities[i] > 100) revert("one of more rarities are above 100");
			assetRarity.push(rarities[i]);
			//increment asset counter
			assets += 1;
		}
	}

	function addAsset(uint256 rarity) public virtual override onlyDeployer {
		if (rarity > 100) revert();

		//increment asset counter
		assetRarity.push(rarity);
		assets += 1;
	}

	//returns randomised colours for SVG Paths
	function getColours(
		uint64 pathSize,
		uint64 pathId,
		RandomNumber randomNumberController
	) public virtual override returns (uint64[] memory result) {
		result = new uint64[](
			pathSize + valuesController.tryGetValue("extraColours")
		);
		for (
			uint64 i = 0;
			i < pathSize + valuesController.tryGetValue("extraColours");
			i++
		) {
			uint256 number = randomNumberController.getMaxNumber(0xFFFFFF);

			if (number <= 0xFFFFFF) result[i] = uint64(number);
			else result[i] = 0;
		}
	}

	function setPathDisabled(uint64 pathId, bool value) public onlyApproved {
		//if path zero is suddenly disabled, we need a new safe path to return
		if (pathId == safeDefaultReturnPath && value) {
			uint256 val = (safeDefaultReturnPath);
			while (disabledPaths[val]) {
				if (val >= kazooPaths.length) val = safeDefaultReturnPath;
				val++;
			}
			safeDefaultReturnPath = val;
		}

		//if we enable zero again then its safe to return 0
		if (pathId <= safeDefaultReturnPath && value)
			safeDefaultReturnPath = pathId;

		disabledPaths[pathId] = value;
	}

	function updatePathGroup(
		uint64 pathId,
		bytes memory paths,
		uint64 pathSize
	) public onlyApproved {
		if (InfinityMintUtil.isEqual(kazooPaths[pathId], "")) revert();

		pathSizes[pathId] = pathSize;
		kazooPaths[pathId] = abi.encode(paths, pathSize);
	}

	function addPathGroups(bytes[] memory paths, uint64[] memory _pathSizes)
		public
		onlyApproved
	{
		require(paths.length == _pathSizes.length);

		for (uint256 i = 0; i < paths.length; i++) {
			pathSizes.push(_pathSizes[i]);
			kazooPaths.push(paths[i]);
		}
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

import "./../../InfinityMintAsset.sol";

contract RarityImage is InfinityMintAsset {
	uint256 lastPath = 0;
	//the rarity of each path
	uint256[] pathRarity;

	constructor(string memory _tokenName, address valuesContract)
		InfinityMintAsset(valuesContract)
	{
		tokenName = _tokenName;
	}

	//save the last path so we may get its name later
	function getNextPathId(RandomNumber randomNumberController)
		public
		virtual
		override
		returns (uint64)
	{
		if (kazooPaths.length == 0) revert("kazooPaths are zero");

		uint256[] memory randNumbers = new uint256[](kazooPaths.length);
		uint256 count = 0;
		//count how many rarity values are greather
		for (uint256 i = 0; i < kazooPaths.length; i++) {
			randNumbers[i] = randomNumberController.getMaxNumber(100);
			if (pathRarity[i] > randNumbers[i]) count++;
		}

		//construct array with length of count
		uint256[] memory selectedPaths = new uint256[](count);
		count = 0; //reset count to zero to use as index position
		for (uint256 i = 0; i < kazooPaths.length; i++) {
			//populate array of selected paths
			if (pathRarity[i] > randNumbers[i]) selectedPaths[count++] = i;
		}

		if (valuesController.isTrue("randomRarity")) {
			//pick an asset
			uint256 result = randomNumberController.getMaxNumber(
				selectedPaths.length
			);
			if (result < selectedPaths.length)
				nextPath = uint64(selectedPaths[result]);
			else {
				//pick an asset
				uint256 randomAssetId = randomNumberController.getMaxNumber(
					kazooPaths.length
				);

				if (disabledPaths[randomAssetId])
					nextPath = uint64(safeDefaultReturnPath);
				else nextPath = uint64(randomAssetId);
			}
		} else {
			uint256 a = 0;
			uint256 b = 0;
			if (valuesController.isTrue("lowestRarity")) {
				for (uint256 i = 0; i < selectedPaths.length; i++) {
					if (a == 0) {
						a = pathRarity[selectedPaths[i]];
						b = selectedPaths[i];
					} else if (pathRarity[i] < a) {
						a = pathRarity[selectedPaths[i]];
						b = selectedPaths[i];
					}
				}

				if (b < kazooPaths.length) nextPath = uint64(b);
				else nextPath = 0;
			} else {
				//default to least rare path selection
				for (uint256 i = 0; i < selectedPaths.length; i++) {
					if (a < pathRarity[selectedPaths[i]]) {
						a = pathRarity[selectedPaths[i]];
						b = selectedPaths[i];
					}
				}

				if (b < kazooPaths.length) nextPath = uint64(b);
				else nextPath = uint64(safeDefaultReturnPath);
			}
		}

		//attempts to stop duplicate mints of the same PathId (does not work with pathId 0)
		if (
			nextPath != 0 &&
			lastPath != 0 &&
			valuesController.isTrue("stopDuplicateMint") &&
			nextPath == lastPath
		) {
			//if it is greater than or equal to two then we have an attempt
			if (selectedPaths.length >= 2) {
				uint64 attempts = 3; //try 3 times
				while (nextPath == lastPath && attempts-- >= 0) {
					//pick an base from the select paths
					uint256 result = randomNumberController.getMaxNumber(
						selectedPaths.length
					);

					//if it is less than
					if (result < selectedPaths.length)
						nextPath = uint64(selectedPaths[result]); //next path is this result
					else nextPath = uint64(selectedPaths[0]); //just use the first value
				}
				//just set it to zero
				if (attempts <= 0) nextPath = uint64(safeDefaultReturnPath);
			} else {
				if (nextPath > 1) nextPath = nextPath - 1;
				else if (nextPath + 1 < kazooPaths.length)
					nextPath = nextPath + 1;
			}
		}

		lastPath = nextPath;
		return nextPath;
	}

	function pushPathRarities(uint256[] memory rarity) public onlyApproved {
		for (uint256 i = 0; i < rarity.length; i++) {
			pathRarity.push(rarity[i]);
		}
	}

	function setPathRarities(uint256[] memory pathId, uint256[] memory rarity)
		public
		onlyApproved
	{
		require(pathId.length == rarity.length);

		for (uint256 i = 0; i < pathId.length; i++) {
			pathRarity[pathId[i]] = rarity[i];
		}
	}

	function setPathRarity(uint256 pathId, uint256 rarity) public onlyApproved {
		require(rarity < 100); //rarity is only out of 100%
		pathRarity[pathId] = rarity;
	}
}