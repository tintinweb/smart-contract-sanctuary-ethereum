/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <8.10.0;
contract Vault {
  struct Node {
    bytes32 id;
    string data;
    bytes32 next;
  }

  mapping(address => Node) public heads;
  mapping(bytes32 => Node) public nodes;
  
  function push(string memory data) public {
    if (heads[msg.sender].next == 0) createHead();

    bytes32 id = keccak256(abi.encodePacked(msg.sender, data, block.timestamp));
    Node memory newNode = Node(id, data, 0);

    Node storage last = heads[msg.sender];
    while (last.next != 0)
      last = nodes[last.next];
    last.next = id;
    nodes[id] = newNode;
  }

  function createHead() internal {
    bytes32 id = keccak256(abi.encodePacked(msg.sender));
    heads[msg.sender] = Node(id, 'head', 0);
  }

  function getAll() public view returns(string[] memory _storage) {
    uint count = 1;
    Node memory last = heads[msg.sender];

    while (last.next != 0) {
      last = nodes[last.next];
      count++;
    }
    _storage = new string[](count);

    last = heads[msg.sender];
    count = 0;
    while (last.next != 0) {
      last = nodes[last.next];
      _storage[count] = (last.data);
      count++;
    }
  }
}