// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract LinkUpUser {
	struct LinkUpUserStruct {
		uint256 link_up_id;
		uint256 user_id;
		string response;
	}

	mapping(uint256 => LinkUpUserStruct) public linkUpUsers;

	uint256 public count = 0;

	/*
	 * CRUD
	 */
	function create(uint256 _link_up_id, uint256 _user_id, string memory _response) public returns (uint256) {
		LinkUpUserStruct storage linkUp = linkUpUsers[count];

		linkUp.link_up_id = _link_up_id;
		linkUp.user_id = _user_id;
		linkUp.response = _response;

		count++;

		return count - 1;
	}
}