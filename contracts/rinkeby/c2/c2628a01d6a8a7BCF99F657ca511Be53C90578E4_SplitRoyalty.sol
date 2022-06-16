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

import "./Authentication.sol";

abstract contract IRoyalty is Authentication {
	//globals
	InfinityMintValues public valuesController;

	//payout values
	mapping(address => uint256) public values;

	uint256 private executionCount;
	uint256 public tokenPrice;
	uint256 public originalTokenPrice;
	uint256 public lastTokenPrice;
	uint256 public freeMints;
	uint256 public stickerSplit;

	uint256 public constant MINT_TYPE = 0;
	uint256 public constant STICKER_TYPE = 1;

	event Withdraw(address indexed sender, uint256 amount, uint256 newTotal);

	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

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

		if (valuesController.tryGetValue("stickerSplit") > 100) revert();
		stickerSplit = valuesController.tryGetValue("stickerSplit");
	}

	function changePrice(uint256 _tokenPrice) public onlyDeployer {
		if (_tokenPrice < originalTokenPrice) revert();

		lastTokenPrice = tokenPrice;
		tokenPrice = _tokenPrice;
	}

	function registerFreeMint() public onlyApproved {
		freeMints = freeMints + 1;
	}

	function withdraw(address addr)
		public
		onlyApproved
		onlyOnce
		returns (uint256 total)
	{
		if (values[addr] <= 0) revert("Invalid or Empty address");

		total = values[addr];
		values[addr] = 0;

		emit Withdraw(addr, total, values[addr]);
	}

	function incrementBalance(uint256 value, uint256 typeOfSplit)
		public
		virtual;
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

import "../IRoyalty.sol";

/**
    Needs
 */
contract SplitRoyalty is IRoyalty {
	mapping(uint256 => uint256) public counter;

	bytes[] private splits;
	uint256 private remainder;

	constructor(address valuesContract) IRoyalty(valuesContract) {}

	function addSplit(
		address addr,
		uint256 percentage,
		uint256 splitType
	) public onlyDeployer {
		splits.push(abi.encode(addr, percentage, splitType));
	}

	function getCount(uint256 typeOfSplit) public view returns (uint256) {
		return counter[typeOfSplit];
	}

	function incrementBalance(uint256 value, uint256 typeOfSplit)
		public
		override
		onlyApproved
		onlyOnce
	{
		if (typeOfSplit != MINT_TYPE && typeOfSplit != STICKER_TYPE) revert();

		counter[typeOfSplit] = counter[typeOfSplit] + 1;

		//if no splits added just give the deployer the entire value
		if (splits.length == 0) {
			values[deployer] = values[deployer] + value;
			return;
		}

		bool flag = false;
		uint256 _value = value;
		for (uint256 i = 0; i < splits.length; i++) {
			if (_value < 0) revert("Too many royalty splits");

			address _addr;
			uint256 percentage;
			uint256 splitType;
			(_addr, percentage, splitType) = abi.decode(
				splits[i],
				(address, uint256, uint256)
			);

			if(percentage <= 0)
				revert("Precentage is less than zero or equal to zero");

			if (splitType != typeOfSplit) continue;

			uint256 profit = ( value / 100 ) * percentage;

			if(profit <= 0)
				revert("Profit is less than or equal zero");

			values[_addr] = values[_addr] + profit;
			_value = _value - profit;
			flag = true;
		}

		require(flag, "did not increment any profits");
		remainder = remainder + _value;
	}

	function resetSplits() public onlyDeployer {
		splits = new bytes[](0);
	}

	function getSplits(address addr)
		public
		view
		returns (uint256[] memory split)
	{
		for (uint256 i = 0; i < splits.length; i++) {
			address _addr;
			uint256 percentage;
			uint256 splitType;
			(_addr, percentage, splitType) = abi.decode(
				splits[i],
				(address, uint256, uint256)
			);

			if (_addr == addr) split[splitType] = percentage;
		}
	}
}