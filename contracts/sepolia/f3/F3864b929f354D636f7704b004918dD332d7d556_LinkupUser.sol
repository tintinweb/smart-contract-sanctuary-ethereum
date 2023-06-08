// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract LinkupUser {
	struct LinkupUserStruct {
		uint256 linkup_id;
		uint256 user_id;
		string response;
	}

	mapping(uint256 => LinkupUserStruct) public linkupUsers;

	uint256 public count = 0;

	/*
	 * CRUD
	 */
	function create(uint256 _linkup_id, uint256 _user_id, string memory _response) public returns (uint256) {
		LinkupUserStruct storage linkup = linkupUsers[count];

		linkup.linkup_id = _linkup_id;
		linkup.user_id = _user_id;
		linkup.response = _response;

		count++;

		return count - 1;
	}
}