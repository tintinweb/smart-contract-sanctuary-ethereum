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

import "./AssetInterface.sol";
import "./Authentication.sol";

abstract contract InfinityMintAsset is AssetInterface, Authentication {
	mapping(uint256 => bool) internal disabledPaths; //disabled paths which are not picked
	mapping(uint256 => uint256[]) public pathSections; //what sections are to what path

	//user values
	InfinityMintValues valuesController;

	//the token name
	string internal tokenName = "asset";
	string public assetsType = "default"; //the type of assetId is default

	//path stuff
	bytes[] internal tokenPaths; //the actual token paths
	uint64[] internal pathSizes; //the amount of points in a path (used in random colour generation with SVG things)
	uint256 internal safeDefaultReturnPath; //used in the case we cannot decide what path to randomly select we will return the value of this

	uint256 internal assetId; //
	uint256[][] internal assetsSections; //the sections to an asset
	uint256[] internal assetRarity; //a list of asset rarity
	uint64[] internal lastAssets; //the last selection of assets
	uint64 internal nextPath; //the next path to be minted

	//the names to pick from when generating
	string[] internal names;

	//location of the projects object URI
	string public objectURI;

	//if all paths are for all sections
	bool private flatSections = false;

	constructor(address valuesContract) {
		valuesController = InfinityMintValues(valuesContract);
		assetRarity.push(0); //so assetId start at 1 not zero so zero can be treat as a
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

	function getNextPath() external view virtual override returns (uint64) {
		return nextPath;
	}

	function setLastAssets(uint64[] memory assets)
		public
		virtual
		override
		onlyApproved
	{
		lastAssets = assets;
	}

	function getPathGroup(uint64 pathId)
		public
		view
		virtual
		override
		returns (bytes memory, uint64)
	{
		require(tokenPaths[pathId].length != 0);
		return abi.decode(tokenPaths[pathId], (bytes, uint64));
	}

	function setPathSize(uint64 pathId, uint64 pathSize) public onlyApproved {
		pathSizes[pathId] = pathSize;
	}

	function getPathSize(uint64 pathId) public view override returns (uint64) {
		if (pathId >= pathSizes.length) return 1;

		return pathSizes[pathId];
	}

	function getNextPathId(RandomNumber randomNumberController)
		public
		virtual
		override
		returns (uint64)
	{
		uint256 result = randomNumberController.getMaxNumber(tokenPaths.length);

		//path is disabled
		if (result >= tokenPaths.length) result = (safeDefaultReturnPath);

		//count up until a non disabled path is found
		while (disabledPaths[result]) {
			if (result + 1 >= tokenPaths.length)
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
		internal
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

	function getDefaultName()
		internal
		virtual
		override
		returns (string memory)
	{
		return tokenName;
	}

	function pickPath(
		uint64 currentTokenId,
		RandomNumber randomNumberController
	)
		public
		virtual
		override
		returns (
			uint64,
			uint64[] memory,
			string[] memory,
			uint64[] memory,
			string memory
		)
	{
		setNextPathId(getNextPathId(randomNumberController));
		setLastAssets(getRandomAsset(nextPath, randomNumberController));

		return (
			getPathSize(nextPath),
			lastAssets,
			getNames(
				uint64(
					randomNumberController.getMaxNumber(
						valuesController.tryGetValue("nameCount")
					)
				),
				randomNumberController
			),
			getColours(nextPath, randomNumberController),
			getMintData(nextPath, currentTokenId, randomNumberController)
		);
	}

	function getRandomAsset(uint64 pathId, RandomNumber randomNumberController)
		public
		view
		virtual
		override
		returns (uint64[] memory assetsId)
	{
		if (assetId == 0) {
			return assetsId;
		}

		uint256[] memory sections;
		if (flatSections) sections = pathSections[0];
		else sections = pathSections[pathId];

		//index position of sections
		uint256 indexPosition = 0;
		//current random number salt
		uint256 salt = randomNumberController.salt();

		if (sections.length == 0) {
			return assetsId;
		} else {
			assetsId = new uint64[](sections.length);
			uint64[] memory selectedPaths;
			for (uint256 i = 0; i < sections.length; i++) {
				uint256[] memory section = assetsSections[sections[i]];

				if (section.length == 0) {
					assetsId[indexPosition++] = 0;
					continue;
				}

				if (section.length == 1 && assetRarity[section[0]] == 100) {
					assetsId[indexPosition++] = uint64(section[0]);
					continue;
				}

				selectedPaths = new uint64[](section.length);
				//repeat filling array with found values
				uint256 count = 0;

				for (uint256 index = 0; index < section.length; index++) {
					if (count == selectedPaths.length) break;
					if (section[index] == 0) continue;

					uint256 rarity = 0;

					if (assetRarity.length > section[index])
						rarity = assetRarity[section[index]];

					if (
						(rarity == 100 ||
							rarity >
							randomNumberController.returnNumber(
								100,
								i +
									index +
									rarity +
									count +
									salt +
									indexPosition
							))
					) selectedPaths[count++] = uint64(section[index]);
				}

				//pick an asset
				uint256 result = 0;

				if (count <= 1) assetsId[indexPosition++] = selectedPaths[0];
				else if (count >= 2) {
					result = randomNumberController.returnNumber(
						count,
						selectedPaths.length + count + indexPosition + salt
					);
					if (result < selectedPaths.length)
						assetsId[indexPosition++] = selectedPaths[result];
					else assetsId[indexPosition++] = 0;
				}
			}
		}
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
			assetId += 1;
		}
	}

	function addAsset(uint256 rarity) public virtual override onlyDeployer {
		if (rarity > 100) revert();

		//increment asset counter
		assetRarity.push(rarity);
		assetId += 1;
	}

	//returns randomised colours for SVG Paths
	function getColours(uint64 pathId, RandomNumber randomNumberController)
		public
		virtual
		override
		returns (uint64[] memory result)
	{
		uint256 pathSize = getPathSize(pathId);
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
				if (val >= tokenPaths.length) val = safeDefaultReturnPath;
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
		require(tokenPaths[pathId].length != 0);

		pathSizes[pathId] = pathSize;
		tokenPaths[pathId] = abi.encode(paths, pathSize);
	}

	function addPathGroups(bytes[] memory paths, uint64[] memory _pathSizes)
		public
		onlyApproved
	{
		require(paths.length == _pathSizes.length);

		for (uint256 i = 0; i < paths.length; i++) {
			pathSizes.push(_pathSizes[i]);
			tokenPaths.push(paths[i]);
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

import "./../../InfinityMintAsset.sol";

/**
	Asset contract to handle SVG mints. Can randomise the colours of an SVG + the names.
 */
contract RaritySVG is InfinityMintAsset {
	uint256[] pathRarity;
	uint256 lastPath = 0;

	constructor(string memory _tokenName, address valuesContract)
		InfinityMintAsset(valuesContract)
	{
		tokenName = _tokenName;
		assetsType = "svg"; //returns scalable vector asset
	}

	//save the last path so we may get its name later
	function getNextPathId(RandomNumber randomNumberController)
		public
		virtual
		override
		returns (uint64)
	{
		if (tokenPaths.length == 1 && disabledPaths[safeDefaultReturnPath])
			revert("No valid paths");
		else if (
			!disabledPaths[safeDefaultReturnPath] && tokenPaths.length == 1
		) {
			return uint64(safeDefaultReturnPath);
		}

		uint256[] memory randNumbers = new uint256[](tokenPaths.length);
		uint256[] memory localRarity = (pathRarity);
		uint64 pathId = uint64(safeDefaultReturnPath);
		uint256 count = 0;

		//count how many rarity values are greather
		for (uint256 i = 0; i < tokenPaths.length; i++) {
			randNumbers[i] = randomNumberController.getMaxNumber(100);
			if (localRarity[i] > randNumbers[i]) count++;
		}

		//construct array with length of count
		uint256[] memory selectedPaths = new uint256[](count);
		count = 0; //reset count to zero to use as index position
		for (uint256 i = 0; i < tokenPaths.length; i++) {
			//populate array of selected paths
			if (localRarity[i] > randNumbers[i]) selectedPaths[count++] = i;
		}

		if (valuesController.isTrue("randomRarity")) {
			//pick an asset
			uint256 result = randomNumberController.getMaxNumber(
				selectedPaths.length
			);
			if (result < selectedPaths.length)
				pathId = uint64(selectedPaths[result]);
			else {
				//pick an asset
				uint256 randomAssetId = randomNumberController.getMaxNumber(
					tokenPaths.length
				);

				if (disabledPaths[randomAssetId])
					pathId = uint64(safeDefaultReturnPath);
				else pathId = uint64(randomAssetId);
			}
		} else {
			uint256 a = 0;
			uint256 b = 0;
			if (valuesController.isTrue("lowestRarity")) {
				for (uint256 i = 0; i < selectedPaths.length; i++) {
					if (a == 0) {
						a = localRarity[selectedPaths[i]];
						b = selectedPaths[i];
					} else if (pathRarity[i] < a) {
						a = localRarity[selectedPaths[i]];
						b = selectedPaths[i];
					}
				}

				if (b < tokenPaths.length) pathId = uint64(b);
				else pathId = 0;
			} else {
				//default to least rare path selection
				for (uint256 i = 0; i < selectedPaths.length; i++) {
					if (a < localRarity[selectedPaths[i]]) {
						a = localRarity[selectedPaths[i]];
						b = selectedPaths[i];
					}
				}

				if (b < tokenPaths.length) pathId = uint64(b);
				else pathId = uint64(safeDefaultReturnPath);
			}
		}

		//attempts to stop duplicate mints of the same PathId (does not work with pathId 0)
		if (
			pathId != 0 &&
			lastPath != 0 &&
			valuesController.isTrue("stopDuplicateMint") &&
			pathId == lastPath
		) {
			uint256 _lastPath = lastPath;
			//if it is greater than or equal to two then we have an attempt
			if (selectedPaths.length >= 2) {
				uint64 attempts = 3; //try 3 times
				while (pathId == _lastPath && attempts-- >= 0) {
					//pick an base from the select paths
					uint256 result = randomNumberController.getMaxNumber(
						selectedPaths.length
					);

					//if it is less than
					if (result < selectedPaths.length)
						pathId = uint64(selectedPaths[result]); //next path is this result
					else pathId = uint64(selectedPaths[0]); //just use the first value
				}
				//just set it to zero
				if (attempts <= 0) pathId = uint64(safeDefaultReturnPath);
			} else {
				if (pathId > 1) pathId = pathId - 1;
				else if (pathId + 1 < tokenPaths.length) pathId = pathId + 1;
			}
		}

		return pathId;
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