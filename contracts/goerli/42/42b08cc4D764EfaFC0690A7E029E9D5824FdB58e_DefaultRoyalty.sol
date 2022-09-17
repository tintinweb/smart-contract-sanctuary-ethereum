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
		require(deployer == msg.sender, "not deployer");
		_;
	}

	modifier onlyApproved() {
		require(msg.sender == deployer || approved[msg.sender], "not approved");
		_;
	}

	function togglePrivilages(address addr) public onlyDeployer {
		approved[addr] = !approved[addr];
	}

	function setPrivilages(address addr, bool value) public onlyDeployer {
		approved[addr] = value;
	}

	function transferOwnership(address addr) public onlyDeployer {
		approved[deployer] = false;
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
	struct InfinityObject {
		uint32 pathId;
		uint32 pathSize;
		uint32 currentTokenId;
		address owner;
		uint32[] colours;
		bytes mintData;
		uint32[] assets;
		string[] names;
		address[] destinations;
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
	/// @param destinations a list of contracts associated with this token
	function createInfinityObject(
		uint32 currentTokenId,
		uint32 pathId,
		uint32 pathSize,
		uint32[] memory assets,
		string[] memory names,
		uint32[] memory colours,
		bytes memory mintData,
		address _sender,
		address[] memory destinations
	) internal pure returns (InfinityObject memory) {
		return
			InfinityObject(
				pathId,
				pathSize,
				currentTokenId,
				_sender, //the sender aka owner
				colours,
				mintData,
				assets,
				names,
				destinations
			);
	}

	/// @notice basically unpacks a return object into bytes.
	function encode(InfinityObject memory data)
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
				abi.encode(data.colours),
				data.mintData,
				data.assets,
				data.names,
				data.destinations
			);
	}

	/// @notice Copied behavours of the open zeppelin content due to prevent msg.sender rewrite through assembly
	function sender() internal view returns (address) {
		return (msg.sender);
	}

	/// @notice Copied behavours of the open zeppelin content due to prevent msg.sender rewrite through assembly
	function value() internal view returns (uint256) {
		return (msg.value);
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

	function filepath(
		string memory directory,
		string memory file,
		string memory extension
	) internal pure returns (string memory) {
		return
			abi.decode(abi.encodePacked(directory, file, extension), (string));
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

	/// @dev Default value it returns is zero
	function tryGetValue(string memory key) external view returns (uint256) {
		if (!registeredValues[key]) return 0;

		return values[key];
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Authentication.sol";

abstract contract Royalty is Authentication {
	//globals
	InfinityMintValues public valuesController;
	address public erc721Destination;

	//payout values
	mapping(address => uint256) public values;
	mapping(uint256 => uint256) public freebies;

	uint256 public tokenPrice;
	uint256 public originalTokenPrice;
	uint256 public lastTokenPrice;
	uint256 public stickerSplit;

	uint8 public constant SPLIT_TYPE_MINT = 0;
	uint8 public constant SPLIT_TYPE_STICKER = 1;

	uint256 internal remainder;

	event DispensedRoyalty(
		address indexed sender,
		uint256 amount,
		uint256 newTotal
	);

	constructor(address valuesContract) {
		valuesController = InfinityMintValues(valuesContract);

		tokenPrice =
			valuesController.tryGetValue("startingPrice") *
			valuesController.tryGetValue("baseTokenValue");
		lastTokenPrice =
			valuesController.tryGetValue("startingPrice") *
			valuesController.tryGetValue("baseTokenValue");
		originalTokenPrice =
			valuesController.tryGetValue("startingPrice") *
			valuesController.tryGetValue("baseTokenValue");

		if (valuesController.tryGetValue("stickerSplit") > 100)
			revert("sticker split is a value over 100");
		stickerSplit = valuesController.tryGetValue("stickerSplit");
	}

	function changePrice(uint256 _tokenPrice) public onlyDeployer {
		lastTokenPrice = tokenPrice;
		tokenPrice = _tokenPrice;
	}

	function registerFree(uint256 splitType) public onlyApproved {
		freebies[splitType]++;
	}

	function dispenseRoyalty(address addr)
		public
		onlyApproved
		onlyOnce
		returns (uint256 total)
	{
		if (values[addr] <= 0) revert("Invalid or Empty address");

		total = values[addr];
		values[addr] = 0;

		emit DispensedRoyalty(addr, total, values[addr]);
	}

	function incrementBalance(uint256 value, uint256 typeOfSplit)
		external
		virtual;
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "../Royalty.sol";

/**
    Needs to only allow the deployer to withdraw/set the price
 */
contract DefaultRoyalty is Royalty {
	mapping(uint256 => uint256) public counter;

	constructor(address valuesContract) Royalty(valuesContract) {}

	function incrementBalance(uint256 value, uint256 splitType)
		external
		override
		onlyApproved
		onlyOnce
	{
		//register as free
		if (value <= 0) {
			registerFree(splitType);
			return;
		}

		counter[splitType] = counter[splitType] + 1;
		//just give the deployer the entire value
		values[deployer] = values[deployer] + value;
	}
}