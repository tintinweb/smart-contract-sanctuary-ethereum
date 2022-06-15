// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

import "./Authentication.sol";
import "./InfinityMintStorage.sol";
import "./IInfinityMintAsset.sol";
import "./IRandomNumber.sol";

abstract contract IInfinityMinter is Authentication {
	InfinityMintValues valuesController;
	InfinityMintStorage storageController;
	IInfinityMintAsset assetController;
	IRandomNumber randomNumberController;

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
		assetController = IInfinityMintAsset(assetContract);
		randomNumberController = IRandomNumber(randomNumberContract);
	}

	function mint(uint64 currentTokenId, address sender)
		public
		virtual
		returns (bytes memory);

	/**
		Fast Mint used in mintAll
	 */
	function implicitMint(
		uint64 currentTokenId,
		uint64 pathId,
		uint64 pathSize,
		bytes memory colours,
		bytes memory mintData,
		address sender
	) public virtual returns (bytes memory);

	/**

     */
	function getPreview(
		uint64 currentTokenId,
		uint64 currentPreviewId,
		address sender
	) public virtual returns (bytes[] memory);

	function selectiveMint(
		uint64 currentTokenId,
		uint256 pathId,
		address sender
	) public virtual returns (bytes memory);

	/*

    */
	function mintPreview(
		uint64 previewId,
		uint64 currentTokenId,
		address sender
	) public virtual returns (bytes memory);
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

import "./InfinityMintObject.sol";

//written by Llydia Cross
contract InfinityMintStorage is InfinityMintObject {
	address private deployer;
	mapping(uint64 => bytes) private previews;
	mapping(uint64 => bytes) private cards;
	mapping(uint64 => bytes) private kazoos;
	mapping(uint64 => address) private registeredKazoos;
	mapping(uint64 => address) private registeredPreviews;
	//public stuff
	mapping(address => bool) public authenticated;
	mapping(address => bool) public previewBlocked;
	mapping(address => uint256) public holders; //holders of token and the number they have
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

		if (kazooId != 0 && firstHeldAt[owner] == 0)
			firstHeldAt[owner] = kazooId;

		holders[owner] = holders[owner] + 1;
		registeredKazoos[kazooId] = owner;
	}

	function transferKazoo(address to, uint64 kazooId)
		public
		onlyAuthenticated
	{
		transferKazoo(kazooId, to);

		(
			uint64 pathId,
			uint64 pathSize,
			uint64 _kazooId,
			address owner, //change it over
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory mintData,
			uint64[] memory assets,
			string[] memory names
		) = InfinityMintUtil.unpackKazoo(get(kazooId));

		owner = to;

		set(
			kazooId,
			abi.encode(
				pathId,
				pathSize,
				_kazooId,
				owner,
				wallet,
				stickers,
				colours,
				mintData,
				assets,
				names
			)
		);
	}

	function setStickerContract(address to, uint64 kazooId)
		public
		onlyAuthenticated
	{
		transferKazoo(kazooId, to);

		(
			uint64 pathId,
			uint64 pathSize,
			uint64 _kazooId,
			address owner, //change it over
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory mintData,
			uint64[] memory assets,
			string[] memory names
		) = InfinityMintUtil.unpackKazoo(get(kazooId));

		stickers = to;

		set(
			kazooId,
			abi.encode(
				pathId,
				pathSize,
				_kazooId,
				owner,
				wallet,
				stickers,
				colours,
				mintData,
				assets,
				names
			)
		);
	}

	function setWalletContract(address to, uint64 kazooId)
		public
		onlyAuthenticated
	{
		transferKazoo(kazooId, to);

		(
			uint64 pathId,
			uint64 pathSize,
			uint64 _kazooId,
			address owner, //change it over
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory mintData,
			uint64[] memory assets,
			string[] memory names
		) = InfinityMintUtil.unpackKazoo(get(kazooId));

		wallet = to;

		set(
			kazooId,
			abi.encode(
				pathId,
				pathSize,
				_kazooId,
				owner,
				wallet,
				stickers,
				colours,
				mintData,
				assets,
				names
			)
		);
	}

	function isPreviewBlocked(address addr) public view returns (bool) {
		return previewBlocked[addr] == true;
	}

	function transferKazoo(uint64 kazooId, address to) public {
		if (registeredKazoos[kazooId] == address(0x0)) revert();

		registeredKazoos[kazooId] = to;
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

	function set(uint64 kazooId, bytes memory data) public onlyAuthenticated {
		kazoos[kazooId] = data;
	}

	function setPreviewBlock(address sender, bool value)
		public
		onlyAuthenticated
	{
		previewBlocked[sender] = value;
	}

	function setPreview(uint64 previewId, bytes calldata data)
		public
		onlyAuthenticated
	{
		previews[previewId] = data;
	}

	function getPreview(uint64 previewId)
		public
		view
		onlyAuthenticated
		returns (bytes memory)
	{
		if (InfinityMintUtil.isEqual(previews[previewId], "")) revert();

		return previews[previewId];
	}

	function deletePreview(uint64 previewId) public onlyAuthenticated {
		if (InfinityMintUtil.isEqual(previews[previewId], "")) revert();

		delete previews[previewId];
	}

	function get(uint64 kazooId) public view returns (bytes memory) {
		if (InfinityMintUtil.isEqual(kazoos[kazooId], "")) revert();

		return kazoos[kazooId];
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

import "./../IInfinityMinter.sol";

contract DefaultMinter is IInfinityMinter {
	/*
	 */
	constructor(
		address valuesContract,
		address storageContract,
		address assetContract,
		address randomNumberContract
	)
		IInfinityMinter(
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
	) public override onlyApproved returns (bytes memory) {
		//unpack our preview project
		(
			uint64 pathId,
			uint64 pathSize,
			uint64 _pId,
			address owner,
			,
			address stickers,
			bytes memory colours,
			bytes memory mintData,
			uint64[] memory assets,
			string[] memory names
		) = InfinityMintUtil.unpackKazoo(
				storageController.getPreview(previewId)
			); //will revert if bad

		//check the owner to see if its the same
		if (owner != sender) revert();
		if (_pId != previewId) revert();
		return
			abi.encode(
				pathId,
				pathSize,
				currentTokenId,
				sender, //the sender aka owner
				address(0x0), //the address of it
				stickers, //stores stickers
				colours,
				mintData,
				assets,
				names
			);
	}

	/**
		Fast Mint used in mintAll
	 */
	function implicitMint(
		uint64 currentTokenId,
		uint64 pathId,
		uint64 pathSize,
		bytes memory colours,
		bytes memory mintData,
		address sender
	) public override onlyApproved returns (bytes memory) {
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
			_encodeImplicitMint(
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
		uint256 pathId,
		address sender
	) public override onlyApproved returns (bytes memory) {}

	/**

     */
	function getPreview(
		uint64 currentTokenId,
		uint64 currentPreviewId,
		address sender
	) public override onlyApproved returns (bytes[] memory previews) {
		previews = new bytes[](valuesController.tryGetValue("previewCount"));

		for (
			uint64 i = 0;
			i < valuesController.tryGetValue("previewCount");
			i++
		) {
			uint64 pathId = assetController.getNextPathId(
				randomNumberController
			);
			uint64 pathSize = assetController.getPathSize(pathId);

			previews[i] = _encodeImplicitMint(
				currentPreviewId,
				pathId,
				pathSize,
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
					pathSize,
					pathId,
					randomNumberController
				),
				bytes("{}"), //removed because of stack to deep
				sender,
				address(0x0)
			);

			storageController.setPreview(currentPreviewId, previews[i]);
			storageController.registerPreview(currentPreviewId, sender);
			currentPreviewId++;
		}

		return previews;
	}

	function _encodeImplicitMint(
		uint64 currentTokenId,
		uint64 pathId,
		uint64 pathSize,
		uint64[] memory assets,
		string[] memory names,
		bytes memory colours,
		bytes memory mintData,
		address sender,
		address wallet
	) internal pure returns (bytes memory) {
		return
			abi.encode(
				pathId,
				pathSize,
				currentTokenId,
				sender, //the sender aka owner
				wallet, //the address of the wallet contract
				address(0x0), //stores stickers
				colours,
				mintData,
				assets,
				names
			);
	}

	/*

    */
	function mint(uint64 currentTokenId, address sender)
		public
		override
		onlyApproved
		returns (bytes memory)
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
			_encodeImplicitMint(
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