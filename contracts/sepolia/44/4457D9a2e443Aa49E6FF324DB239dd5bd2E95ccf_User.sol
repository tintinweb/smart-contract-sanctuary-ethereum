// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract User {
	struct UserStruct {
		address owner;
		string firstName;
		string lastName;
		string email;
		uint256 dateOfBirth;
		uint256 phoneNumber;
		string gender;
		uint256[] friends;
	}

	mapping(uint256 => UserStruct) public users;

	uint256 public count = 0;

	function create(
		address _owner,
		string memory _firstName,
		string memory _lastName,
		string memory _email,
		string memory _gender,
		uint256 _dateOfBirth,
		uint256 _phoneNumber
	) public returns (uint256) {
		UserStruct storage user = users[count];

		// require(_dateOfBirth > block.timestamp, 'DOB should be in the future.');

		user.owner = _owner;
		user.firstName = _firstName;
		user.lastName = _lastName;
		user.email = _email;
		user.gender = _gender;
		user.dateOfBirth = _dateOfBirth;
		user.phoneNumber = _phoneNumber;

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
}