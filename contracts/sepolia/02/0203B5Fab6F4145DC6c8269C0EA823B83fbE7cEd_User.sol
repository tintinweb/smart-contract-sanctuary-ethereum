// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract User {
	struct UserStruct {
		address owner;
		string fullName;
		string[] musicTaste;
		uint256[] contacts;
	}

	mapping(uint256 => UserStruct) public users;

	uint256 public count = 0;

	/*
	 * CRUD
	 */
	function create(address _owner, string memory _fullName, string[] memory _musicTaste) public returns (uint256) {
		UserStruct storage user = users[count];

		user.owner = _owner;
		user.fullName = _fullName;
		user.musicTaste = _musicTaste;

		count++;

		return count - 1;
	}

	function getAll() public view returns (UserStruct[] memory) {
		UserStruct[] memory allUsers = new UserStruct[](count);

		for (uint i = 0; i < count; i++) {
			UserStruct storage item = users[i];

			allUsers[i] = item;
		}

		return allUsers;
	}

	/*
	 * Links
	 */
	function addLink(uint256 user_id, uint256 contact_id) public {
		UserStruct storage user = users[user_id];

		user.contacts.push(contact_id);
	}
}