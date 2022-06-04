// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./dvy_permissions.sol";

contract DVYContentGroup is DVYPermissions {
  struct Content {
    string ipfs_cid;
    string title;
    uint256 timestamp;
    address content_owner;
  }

  Content[] private _content_list;


  constructor(
    address[] memory __moderators,
    string memory __name
  ) DVYPermissions(__moderators, __name) {
  }

  function addContent(string memory __ipfs_cid, string memory __title) public onlyModerators {
    Content memory content = Content({
      ipfs_cid: __ipfs_cid,
      title: __title,
      timestamp: block.timestamp,
      content_owner: msg.sender
    });
    _content_list.push(content);
  }

  function removeContent(string memory __ipfs_cid) public onlyModerators {
    for (uint256 i = 0; i < _content_list.length; i++) {
      if (keccak256(abi.encodePacked(_content_list[i].ipfs_cid)) == keccak256(abi.encodePacked(__ipfs_cid))) {
        delete _content_list[i];
      }
    }
  }

  function contentAt(uint256 index) public view returns (Content memory) {
    return _content_list[index];
  }

  function contentCount() public view returns (uint256) {
    return _content_list.length;
  }

  function allContent() public view returns (Content[] memory) {
    return _content_list;
  }

  function tip() public payable {
    uint256 amountPerContent = msg.value / _content_list.length;
    for (uint256 i = 0; i < _content_list.length; i++) {
      (bool os, ) = payable(_content_list[i].content_owner).call{ value: amountPerContent }("");
      require(os);
    }
  }
}