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

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";

abstract contract Authentication is InfinityMintObject {
	address deployer;

	mapping(address => bool) internal approved;

	constructor() {
		deployer = sender();
		approved[sender()] = true;
	}

	modifier onlyDeployer() {
		if (sender() != deployer) revert();
		_;
	}

	modifier onlyApproved() {
		if (approved[sender()] == false) revert();
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

import "./IRandomNumber.sol";
import "./InfinityMintObject.sol";

abstract contract IInfinityMintAsset is InfinityMintObject {
	function getColours(
		uint64 pathSize,
		uint64 pathId,
		IRandomNumber randomNumberController
	) public virtual returns (bytes memory result);

	function getObjectURI() public view virtual returns (string memory) {
		return "";
	}

	function getDefaultName() public virtual returns (string memory);

	function addColour(uint64 pathId, bytes memory colours) public virtual;

	function getNames(uint64 nameCount, IRandomNumber randomNumberController)
		public
		virtual
		returns (string[] memory results);

	function getRandomAsset(uint64 pathId, IRandomNumber randomNumberController)
		public
		virtual
		returns (uint64[] memory assetsId);

	function getAsset(uint64 assetId)
		public
		view
		virtual
		returns (bytes memory);

	function getMintData(
		uint64 pathId,
		uint64 tokenId,
		IRandomNumber randomNumberController
	) public virtual returns (bytes memory);

	function addAsset(uint256 rarity, bytes memory asset) public virtual;

	function getNextName(IRandomNumber randomNumberController)
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

	function getNextPathId(IRandomNumber randomNumberController)
		public
		virtual
		returns (uint64);
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;
//SafeMath Contract
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./InfinityMintValues.sol";

abstract contract IRandomNumber {
	uint256 internal numberSeed = 42069420;
	uint256 public randomnessFactor;
	uint256 internal nonce = 14928;
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
	{
		if (maxNumber < 0) maxNumber = 0;
		uint256 c = uint256(
			keccak256(
				abi.encode(
					nonce++,
					numberSeed,
					maxNumber,
					msg.sender,
					block.timestamp,
					randomnessFactor
				)
			)
		);

		(bool safe, uint256 result) = SafeMath.tryMod(c, maxNumber);

		if (safe) return result;

		return 0;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

//SafeMath Contract
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IInfinityMintAsset.sol";
import "./Authentication.sol";

abstract contract InfinityMintAsset is IInfinityMintAsset, Authentication {
	mapping(uint256 => uint256[]) pathSections;
	mapping(uint256 => uint256[]) assetsSections;
	mapping(uint64 => uint64) duplicates;
	mapping(uint64 => uint64) pathSizes;
	//paths are a complete
	bytes[] internal kazooPaths;
	bytes[] internal assets;
	uint256[] internal assetRarity;
	string[] internal names;
	uint64[] internal lastAssets;

	string public assetsType = "default";
	uint64 public nextPath;

	InfinityMintValues valuesController;

	string public objectURI;

	constructor(address valuesContract) {
		valuesController = InfinityMintValues(valuesContract);
		assets.push(bytes("")); //so assets start at 1 not zero so zero can be treat as a
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

	/**
        For default implementation, it selects a pathgroup by random, this can be overwritten
    **/

	function getNextPathId(IRandomNumber randomNumberController)
		public
		virtual
		override
		returns (uint64)
	{
		(bool safe, uint256 result) = SafeMath.tryMod(
			(randomNumberController.getNumber() + 1),
			kazooPaths.length
		);

		if (safe && result < kazooPaths.length) return uint64(result);
		return 0;
	}

	/**
        Helper function to get a random name from the name of keys
     */
	function getRandomNameKey(IRandomNumber randomNumberController)
		internal
		returns (uint64)
	{
		(bool safe, uint256 result) = SafeMath.tryMod(
			(randomNumberController.getNumber() + 1),
			names.length
		);

		if (safe && result < names.length) return uint64(result);

		return 0;
	}

	function getNextName(IRandomNumber randomNumberController)
		public
		virtual
		override
		returns (string memory)
	{
		if (names.length == 0) return "null";

		return names[getRandomNameKey(randomNumberController)];
	}

	function getNames(uint64 nameCount, IRandomNumber randomNumberController)
		public
		virtual
		override
		returns (string[] memory results)
	{
		results = _getNames(nameCount, randomNumberController);
	}

	/**

	 */
	function _getNames(uint64 nameCount, IRandomNumber randomNumberController)
		internal
		virtual
		returns (string[] memory results)
	{
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

	function getAsset(uint64 assetId)
		public
		view
		virtual
		override
		returns (bytes memory)
	{
		if (assetId <= 0) revert();

		if (InfinityMintUtil.isEqual(assets[assetId], ""))
			revert("Invalid Asset");

		return assets[assetId];
	}

	function getMintData(
		uint64 pathId,
		uint64 tokenId,
		IRandomNumber randomNumberController
	) public virtual override returns (bytes memory) {
		return bytes("{}"); //returns a blank json array
	}

	function getDefaultName() public virtual override returns (string memory) {
		return "Token";
	}

	function addColour(uint64 pathId, bytes memory colours)
		public
		virtual
		override
		onlyDeployer
	{}

	function getRandomAsset(uint64 pathId, IRandomNumber randomNumberController)
		public
		virtual
		override
		returns (uint64[] memory assetsId)
	{
		assetsId = new uint64[](0);

		if (assets.length == 0) {
			lastAssets = assetsId;
			return assetsId;
		}

		uint256[] memory sections = pathSections[pathId];
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

				uint256 count = 0;
				uint256[] memory randNumbers = new uint256[](section.length);
				for (uint256 index = 0; index < section.length; index++) {
					if (section[index] == 0) continue;
					uint256 rarity = 0;

					if (assetRarity.length > section[index])
						rarity = assetRarity[section[index]];

					randNumbers[index] = randomNumberController.getMaxNumber(
						100
					);
					if (rarity > randNumbers[index]) count++;
				}

				uint256[] memory selectedPaths = new uint256[](count);

				if (selectedPaths.length == 0) {
					assetsId[indexPosition++] = 0;
					continue;
				}

				//repeat filling array with found values
				count = 0;
				for (uint256 index = 0; index < section.length; index++) {
					if (section[index] == 0) continue;
					uint256 rarity = 0;

					if (assetRarity.length > section[index])
						rarity = assetRarity[section[index]];

					if (rarity > randNumbers[index])
						selectedPaths[count++] = section[index];
				}

				//pick an asset
				(bool safe, uint256 result) = SafeMath.tryMod(
					(randomNumberController.getNumber() + 1),
					selectedPaths.length
				);

				if (safe && selectedPaths.length > result)
					assetsId[indexPosition++] = uint64(selectedPaths[result]);
				else if (selectedPaths.length >= 1)
					assetsId[indexPosition++] = uint64(selectedPaths[0]);
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

	function setPathSections(
		uint64[] memory pathIds,
		uint256[][] memory _sections
	) public onlyDeployer {
		require(pathIds.length == _sections.length);

		for (uint256 i = 0; i < pathIds.length; i++) {
			pathSections[pathIds[i]] = _sections[i];
		}
	}

	function addAssets(uint256[] memory rarities, bytes[] memory _assets)
		public
		onlyDeployer
	{
		require(rarities.length == _assets.length);

		for (uint256 i = 0; i < rarities.length; i++) {
			assetRarity.push(rarities[i]);
			assets.push(_assets[i]);
		}
	}

	function addAsset(uint256 rarity, bytes memory asset)
		public
		virtual
		override
		onlyDeployer
	{
		if (rarity > 100) revert();

		assets.push(asset);
		assetRarity.push(rarity);
	}

	//returns randomised colours for SVG Paths
	function getColours(
		uint64 pathSize,
		uint64 pathId,
		IRandomNumber randomNumberController
	) public virtual override returns (bytes memory result) {
		return
			abi.encode(_getColours(pathSize, pathId, randomNumberController));
	}

	//returns randomised colours for SVG Paths
	function _getColours(
		uint64 pathSize,
		uint64 pathId,
		IRandomNumber randomNumberController
	) public virtual returns (uint24[] memory result) {
		result = new uint24[](
			pathSize + valuesController.tryGetValue("extraColours")
		);
		for (
			uint64 i = 0;
			i < pathSize + valuesController.tryGetValue("extraColours");
			i++
		) {
			(bool safe, uint256 number) = SafeMath.tryMod(
				(randomNumberController.getNumber() + pathId),
				0xFFFFFF
			);

			if (safe) result[i] = uint24(number);
			else result[i] = 0;
		}
	}

	function updatePathGroup(
		uint64 pathId,
		bytes memory paths,
		uint64 pathSize
	) public onlyApproved {
		pathSizes[pathId] = pathSize;

		if (InfinityMintUtil.isEqual(kazooPaths[pathId], "")) revert();

		kazooPaths[pathId] = abi.encode(paths, pathSize);
	}

	function addPathGroups(bytes[] memory paths, uint64[] memory _pathSizes)
		public
		onlyApproved
	{
		require(paths.length == _pathSizes.length);

		for (uint256 i = 0; i < paths.length; i++) {
			pathSizes[uint64(kazooPaths.length)] = _pathSizes[i];
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
	/*
		Isn't a garuntee
	*/
	modifier onlyContract() {
		uint256 size;
		address account = sender();

		assembly {
			size := extcodesize(account)
		}
		if (size > 0) _;
		else revert();
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

import "../../InfinityMintAsset.sol";

/**

		Colours of a smart token
			- Since colours aren't being randomized or uploaded with a smart token, the
			colours is going to only be the extra colours.
			- Names are randomly generated based on the contracts max name count, used the Matched variant to do non random names
			-
	 */

contract RarityImage is InfinityMintAsset {
	string internal tokenName;

	//the rarity of each path
	mapping(uint256 => uint256) pathRarity;

	uint256 lastPath = 0;

	/**

	 */

	constructor(string memory _tokenName, address valuesContract)
		InfinityMintAsset(valuesContract)
	{
		tokenName = _tokenName;
		assetsType = "image";
	}

	function getNames(uint64 nameCount, IRandomNumber randomNumberController)
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
		} else return _getNames(nameCount, randomNumberController);
	}

	//save the last path so we may get its name later
	function getNextPathId(IRandomNumber randomNumberController)
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
			(bool safe, uint256 result) = SafeMath.tryMod(
				(randomNumberController.getNumber() + 1),
				selectedPaths.length
			);

			if (safe && result < selectedPaths.length)
				nextPath = uint64(selectedPaths[result]);
			else {
				//pick an asset
				(bool safeResult, uint256 randomAssetId) = SafeMath.tryMod(
					(randomNumberController.getNumber() + 1),
					kazooPaths.length
				);

				if (safeResult && randomAssetId < kazooPaths.length)
					nextPath = uint64(randomAssetId);
				else nextPath = 0;
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
				else nextPath = 0;
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
				uint64 attempts = 20; //try 10 times to get a new
				while (nextPath == lastPath && attempts-- >= 0) {
					//pick an asset
					(bool safe, uint256 result) = SafeMath.tryMod(
						(randomNumberController.getNumber() + 1),
						selectedPaths.length
					);

					if (safe && result < selectedPaths.length)
						nextPath = uint64(selectedPaths[result]);
					else nextPath = uint64(selectedPaths[0]); //just use the first value
				}
				//just set it to zero
				if (attempts <= 0) nextPath = 0;
			} else {
				if (nextPath > 1) nextPath = nextPath - 1;
				else if (nextPath + 1 < kazooPaths.length)
					nextPath = nextPath + 1;
			}
		}

		lastPath = nextPath;
		return nextPath;
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

	/*
	 */
	function getColours(
		uint64 pathSize, //might be 0
		uint64 pathId,
		IRandomNumber randomNumberController
	) public override returns (bytes memory result) {
		uint32[] memory colours = new uint32[](
			pathSize + valuesController.tryGetValue("extraColours")
		);

		for (
			uint256 i = 0;
			i < pathSize + valuesController.tryGetValue("extraColours");
			i++
		) {
			(bool safe, uint256 number) = SafeMath.tryMod(
				(randomNumberController.getNumber() + 1),
				0xFFFFFF
			);

			if (safe) colours[i] = uint32(number);
			else colours[i] = 0;
		}

		return abi.encode(colours);
	}

	/** */
	function getDefaultName() public view override returns (string memory) {
		return tokenName;
	}
}