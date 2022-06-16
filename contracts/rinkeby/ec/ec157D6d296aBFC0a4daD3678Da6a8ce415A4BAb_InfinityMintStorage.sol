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