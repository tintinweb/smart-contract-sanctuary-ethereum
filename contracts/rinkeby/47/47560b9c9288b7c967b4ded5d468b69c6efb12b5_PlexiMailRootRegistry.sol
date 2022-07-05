/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract PlexiMailRootRegistry {
  
  struct Binding {
    string ipnsRecord;
    string signedPreKeySignature;
  }

  mapping (address => Binding) private bindings;
  address private owner;
  
  constructor() {
      owner = msg.sender;
  }

  modifier isOwner() {
    require(msg.sender == owner, "Caller is not owner");
    _;
  }

  function addBinding(string calldata ipnsRecord, string calldata signedPreKeySignature) public {
    Binding memory binding = Binding({
        ipnsRecord: ipnsRecord,
        signedPreKeySignature: signedPreKeySignature
    });
    bindings[msg.sender] = binding;
  }

  function getBinding(address address_) public view returns (string memory, string memory) {
    Binding memory binding = bindings[address_];
    return (binding.ipnsRecord, binding.signedPreKeySignature);
  }
}