/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingTest {
  address public owner;
  mapping(address => bool) public members;
  mapping(bytes32 => mapping(address => uint256)) public votes;
  mapping(bytes32 => uint256) public yeys;

  modifier onlyOwner() {
    require(msg.sender == owner, 'no owner role');
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function addMember(address _member) external onlyOwner returns (bool) {
    members[_member] = true;
    return true;
  }

  function verifySigs(bytes32 _topicHash, bytes[] memory _sigs) public returns (bool) {
    for(uint256 i = 0; i < _sigs.length; i++) {
      address signer = recover(_topicHash, _sigs[i]);
      //if(members[signer] && votes[_topicHash][signer] == 0) {
      if(members[signer]) {
        votes[_topicHash][signer]++;
        yeys[_topicHash]++;
      }
    }
    return true;
  }

  function recover(bytes32 _hash, bytes memory _sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    //Check the signature length
    if (_sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(_hash, v, r, s);
    }
  }
}