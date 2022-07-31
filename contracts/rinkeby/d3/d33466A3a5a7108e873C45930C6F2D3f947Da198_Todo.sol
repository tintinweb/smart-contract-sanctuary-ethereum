// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Todo {
  struct Item {
    string name;
    bool done;
  }

  Item[] private items;

  function addItem(string memory _name) external {
    items.push(Item(_name, false));
  }

  function updateStatus(uint256 _id, bool _done) external {
    items[_id].done = _done;
  }

  function removeItem(uint256 _id) external {
    delete items[_id];
  }

  function getItems() external view returns (Item[] memory) {
    return items;
  }

  function getItemById(uint256 _id) external view returns (Item memory) {
    return items[_id];
  }
}