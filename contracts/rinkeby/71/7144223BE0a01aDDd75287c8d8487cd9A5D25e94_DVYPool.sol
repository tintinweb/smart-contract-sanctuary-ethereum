// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./dvy_permissions.sol";

contract DVYPool is DVYPermissions {
  address[] private _group_list;

  constructor(
    address[] memory __moderators,
    string memory __name
  ) DVYPermissions(__moderators, __name) {
  }

  function addContentGroup(address __group) public onlyModerators {
    _group_list.push(__group);
  }

  function removeContentGroup(address __group) public onlyModerators {
    for (uint256 i = 0; i < _group_list.length; i++) {
      if (_group_list[i] == __group) {
        delete _group_list[i];
      }
    }
  }

  function tip() public payable {
    require(msg.value > 0, "You must tip at least 1.");
    require(msg.value > _moderators.length, "You must tip at least 1 per moderator.");
    uint256 amountPerModerator = msg.value / _group_list.length;
    for (uint256 i = 0; i < _moderators.length; i++) {
      (bool os, ) = payable(_moderators[i]).call{ value: amountPerModerator }("");
      require(os);
    }
  }

  function groupAt(uint256 index) public view returns (address) {
    return _group_list[index];
  }

  function groupCount() public view returns (uint256) {
    return _group_list.length;
  }

  function allGroups() public view returns (address[] memory) {
    return _group_list;
  }
}