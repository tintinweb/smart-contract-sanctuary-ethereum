// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract UserLinkup {
	struct UserLinkupStruct {
		uint256 linkup_id;
		uint256 user_id;
		string response;
	}

	mapping(uint256 => UserLinkupStruct) public userLinkups;

	uint256 public count = 0;

	/*
	 * CRUD
	 */
	function create(uint256 _linkup_id, uint256 _user_id, string memory _response) public returns (uint256) {
		UserLinkupStruct storage linkup = userLinkups[count];

		linkup.linkup_id = _linkup_id;
		linkup.user_id = _user_id;
		linkup.response = _response;

		count++;

		return count - 1;
	}
}