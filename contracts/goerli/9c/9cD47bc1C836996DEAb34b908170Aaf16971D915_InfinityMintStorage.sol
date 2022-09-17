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

import "./InfinityMintObject.sol";
import "./Authentication.sol";

/// @title InfinityMint storage controller
/// @author Llydia Cross
/// @notice Stores the outcomes of the mint process and previews and also unlock keys
/// @dev Attached to to an InfinityMint
contract InfinityMintStorage is Authentication, InfinityMintObject {
	/// @notice previews
	mapping(address => mapping(uint256 => InfinityObject)) public previews;
	/// @notice previews timestamps of when new previews can be made
	mapping(address => uint256) public previewTimestamp;
	/// @notice all of the token data
	mapping(uint32 => InfinityObject) private tokens;
	/// @notice Address flags can be toggled and effect all of the tokens
	mapping(address => mapping(string => bool)) private flags;
	/// @notice a list of tokenFlags associated with the token
	mapping(uint256 => mapping(string => bool)) public tokenFlags;
	/// @notice a list of options
	mapping(address => mapping(string => string)) private options;
	/// @notice private mapping holding a list of tokens for owned by the address for quick look up
	mapping(address => uint32[]) private registeredTokens;

	/// @notice returns true if the address is preview blocked and unable to receive more previews
	function getPreviewTimestamp(address addr) external view returns (uint256) {
		return previewTimestamp[addr];
	}

	/// @notice sets a time in the future they an have more previews
	function setPreviewTimestamp(address addr, uint256 timestamp)
		public
		onlyApproved
	{
		require(timestamp > block.timestamp, "timestamp must be in the future");
		previewTimestamp[addr] = timestamp;
	}

	/// @notice Allows those approved with the contract to directly force a token flag. The idea is a seperate contract would control immutable this way
	/// @dev NOTE: This can only be called by contracts to curb rugging potential
	function forceTokenFlag(
		uint256 tokenId,
		string memory _flag,
		bool position
	) public onlyApproved {
		tokenFlags[tokenId][_flag] = position;
	}

	//// @notice Allows the current token owner to toggle a flag on the token, for instance, locked flag being true will mean token cannot be transfered
	function setTokenFlag(
		uint256 tokenId,
		string memory _flag,
		bool position
	) public {
		require(this.flag(tokenId, "immutable") != true, "token is immutable");
		require(
			!InfinityMintUtil.isEqual(bytes(_flag), "immutable"),
			"token immutable/mutable state cannot be modified this way for security reasons"
		);
		tokenFlags[tokenId][_flag] = position;
	}

	/// @notice returns the value of a flag
	function flag(uint256 tokenId, string memory _flag)
		external
		view
		returns (bool)
	{
		return tokenFlags[tokenId][_flag];
	}

	/// @notice sets an option for a users tokens
	/// @dev this is used for instance inside of tokenURI
	function setOption(
		address addr,
		string memory key,
		string memory option
	) public onlyApproved {
		options[addr][key] = option;
	}

	/// @notice deletes an option
	function deleteOption(address addr, string memory key) public onlyApproved {
		delete options[addr][key];
	}

	/// @notice returns a global option for all the addresses tokens
	function getOption(address addr, string memory key)
		external
		view
		returns (string memory)
	{
		return options[addr][key];
	}

	//// @notice Allows the current token owner to toggle a flag on the token, for instance, locked flag being true will mean token cannot be transfered
	function setFlag(
		address addr,
		string memory _flag,
		bool position
	) public onlyApproved {
		flags[addr][_flag] = position;
	}

	function tokenFlag(uint32 tokenId, string memory _flag)
		external
		view
		returns (bool)
	{
		return tokenFlags[tokenId][_flag];
	}

	function validDestination(uint32 tokenId, uint256 index)
		external
		view
		returns (bool)
	{
		return (tokens[tokenId].owner != address(0x0) &&
			tokens[tokenId].destinations.length != 0 &&
			index < tokens[tokenId].destinations.length &&
			tokens[tokenId].destinations[index] != address(0x0));
	}

	/// @notice returns the value of a flag
	function flag(address addr, string memory _flag)
		external
		view
		returns (bool)
	{
		return flags[addr][_flag];
	}

	/// @notice returns address of the owner of this token
	/// @param tokenId the tokenId to get the owner of
	function getOwner(uint32 tokenId) public view returns (address) {
		return tokens[tokenId].owner;
	}

	/// @notice returns an integer array containing the token ids owned by the owner address
	/// @dev NOTE: This will only track 256 tokens
	/// @param owner the owner to look for
	function getAllRegisteredTokens(address owner)
		public
		view
		returns (uint32[] memory)
	{
		return registeredTokens[owner];
	}

	/// @notice this method adds a tokenId from the registered tokens list which is kept for the owner. these methods are designed to allow limited data retrival functionality on local host environments
	/// @dev for local testing purposes mostly, to make it scalable the length is capped to 128. Tokens should be indexed by web2 server not on chain.
	/// @param owner the owner to add the token too
	/// @param tokenId the tokenId to add
	function addToRegisteredTokens(address owner, uint32 tokenId)
		public
		onlyApproved
	{
		//if the l
		if (registeredTokens[owner].length < 128)
			registeredTokens[owner].push(tokenId);
	}

	/// @notice Gets the amount of registered tokens
	/// @dev Tokens are indexable instead by their current positon inside of the owner wallets collection, returns a tokenId
	/// @param owner the owner to get the length of
	function getRegisteredTokenCount(address owner)
		public
		view
		returns (uint256)
	{
		return registeredTokens[owner].length;
	}

	/// @notice returns a token
	/// @dev returns an InfinityObject defined in {InfinityMintObject}
	/// @param tokenId the tokenId to get
	function get(uint32 tokenId) public view returns (InfinityObject memory) {
		if (tokens[tokenId].owner == address(0x0)) revert("invalid token");

		return tokens[tokenId];
	}

	/// @notice Sets the owner field in the token to another value
	function transfer(address to, uint32 tokenId) public onlyApproved {
		//set to new owner
		tokens[tokenId].owner = to;
	}

	function set(uint32 tokenId, InfinityObject memory data)
		public
		onlyApproved
	{
		require(data.owner != address(0x0), "null owner");
		require(data.currentTokenId == tokenId, "tokenID mismatch");
		tokens[tokenId] = data;
	}

	/// @notice use normal set when can because of the checks it does before the set, this does no checks
	function setUnsafe(uint32 tokenId, bytes memory data) public onlyApproved {
		tokens[tokenId] = abi.decode(data, (InfinityObject));
	}

	function setPreview(
		address owner,
		uint256 index,
		InfinityObject memory data
	) public onlyApproved {
		previews[owner][index] = data;
	}

	function getPreviewAt(address owner, uint256 index)
		external
		view
		returns (InfinityObject memory)
	{
		require(
			previews[owner][index].owner != address(0x0),
			"invalid preview"
		);

		return previews[owner][index];
	}

	function findPreviews(address owner, uint256 previewCount)
		public
		view
		onlyApproved
		returns (InfinityObject[] memory)
	{
		InfinityObject[] memory temp = new InfinityObject[](previewCount);
		for (uint256 i = 0; i < previewCount; ) {
			temp[i] = previews[owner][i];

			unchecked {
				++i;
			}
		}

		return temp;
	}

	function deletePreview(address owner, uint256 previewCount)
		public
		onlyApproved
	{
		for (uint256 i = 0; i < previewCount; ) {
			delete previews[owner][i];

			unchecked {
				++i;
			}
		}

		delete previewTimestamp[owner];
	}

	/// @notice this method deletes a tokenId from the registered tokens list which is kept for the owner. these methods are designed to allow limited data retrival functionality on local host environments
	/// @dev only works up to 256 entrys, not scalable
	function deleteFromRegisteredTokens(address sender, uint32 tokenId) public {
		if (registeredTokens[sender].length - 1 <= 0) {
			registeredTokens[sender] = new uint32[](0);
			return;
		}

		uint32[] memory newArray = new uint32[](
			registeredTokens[sender].length - 1
		);
		uint256 index = 0;
		for (uint256 i = 0; i < registeredTokens[sender].length; ) {
			if (index == newArray.length) break;
			if (tokenId == registeredTokens[sender][i]) {
				unchecked {
					++i;
				}
				continue;
			}

			newArray[index++] = registeredTokens[sender][i];

			unchecked {
				++i;
			}
		}

		registeredTokens[sender] = newArray;
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