// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CrossChainKYCPOC {
	struct IDStruct {
		bytes32 namehash;
		address sender_address;
		bytes serialisedData;
		bytes[] multi_chain_address;
	}

	mapping(bytes32 => IDStruct) db; //mapping of nameHash => ID
	mapping(address => bytes32) reverseDBMapping;

	function isSenderRegistered(
		string memory _name,
		string memory _chain
	) public view returns (bool) {
		bytes32 nameHash = computeNameChainhash(_name, _chain);
		if (db[nameHash].sender_address == msg.sender) {
			return true;
		}
		return false;
	}

	function computeNameHash(
		string memory _name
	) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(_name));
	}

	function computeNameChainhash(
		string memory _name,
		string memory _chain
	) internal pure returns (bytes32 namehash) {
		namehash = keccak256(
			abi.encodePacked(namehash, keccak256(abi.encodePacked(_name)))
		);
		namehash = keccak256(
			abi.encodePacked(namehash, keccak256(abi.encodePacked(_chain)))
		);
	}

	function getNameHash(
		string memory _name,
		string memory _chain
	) external pure returns (bytes32) {
		return computeNameChainhash(_name, _chain);
	}

	function getID(bytes32 nameHash) external view returns (IDStruct memory) {
		return db[nameHash];
	}

	function getSerialisedID(
		bytes32 nameHash
	) external view returns (bytes memory) {
		return db[nameHash].serialisedData;
	}

	function decode(bytes memory _data) external pure returns (string memory) {
		return abi.decode(_data, (string));
	}

	function fetchIDFromAddress() public view returns (IDStruct memory userID) {
		bytes32 nameHash = reverseDBMapping[msg.sender];
		return db[nameHash];
	}

	function storeID(
		string memory _name,
		string memory _parent_chain
	) external returns (IDStruct memory) {
		bool isRegistered = isSenderRegistered(_name, _parent_chain);

		if (isRegistered) {
			revert("Sender already registered");
		}

		bytes32 nameHash = computeNameChainhash(_name, _parent_chain);

		bytes memory serialisedData = abi.encode(_name); // other identity data

		// hashedChain is using address instead of string
		// address => string before hashing
		bytes memory hashedChain = abi.encode(_parent_chain, msg.sender);

		bytes[] memory multi_chain_address = new bytes[](1);

		multi_chain_address[0] = hashedChain;

		IDStruct memory id = IDStruct(
			nameHash,
			msg.sender,
			serialisedData,
			multi_chain_address
		);
		db[nameHash] = id;
		reverseDBMapping[msg.sender] = nameHash;

		return id;
	}

	function addChain(
		string memory _name,
		string memory _registered_chain,
		string memory _new_chain,
		string memory _new_chain_address
	) external {
		bytes32 nameHash = computeNameChainhash(_name, _registered_chain);

		if (db[nameHash].sender_address != msg.sender) {
			revert("Sender not registered");
		}

		bytes memory newHashedChain = abi.encode(
			_new_chain,
			_new_chain_address
		);

		db[nameHash].multi_chain_address.push(newHashedChain);
	}

	function decodeChain(
		bytes memory _hash
	) external pure returns (string memory chain, string memory user_address) {
		(chain, user_address) = abi.decode(_hash, (string, string));
	}

	function decodeRegisteringChain(
		bytes memory _hash
	) external pure returns (string memory chain, address user_address) {
		(chain, user_address) = abi.decode(_hash, (string, address));
	}
}