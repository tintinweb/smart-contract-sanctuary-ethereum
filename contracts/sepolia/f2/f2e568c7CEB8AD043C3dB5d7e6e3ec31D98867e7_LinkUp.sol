// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract LinkUp {
	struct LinkUpStruct {
		address owner;
		string name;
		string description;
		string location;
		uint256 moment;
	}

	mapping(uint256 => LinkUpStruct) public linkUps;

	uint256 public count = 0;

	/*
	 * CRUD
	 */
	function create(
		address _owner,
		string memory _name,
		string memory _description,
		string memory _location,
		uint256 _moment
	) public returns (uint256) {
		LinkUpStruct storage linkUp = linkUps[count];

		linkUp.owner = _owner;
		linkUp.name = _name;
		linkUp.description = _description;
		linkUp.location = _location;
		linkUp.moment = _moment;

		count++;

		return count - 1;
	}

	function getAll() public view returns (LinkUpStruct[] memory) {
		LinkUpStruct[] memory allLinkUps = new LinkUpStruct[](count);

		for (uint i = 0; i < count; i++) {
			LinkUpStruct storage item = linkUps[i];

			allLinkUps[i] = item;
		}

		return allLinkUps;
	}
}