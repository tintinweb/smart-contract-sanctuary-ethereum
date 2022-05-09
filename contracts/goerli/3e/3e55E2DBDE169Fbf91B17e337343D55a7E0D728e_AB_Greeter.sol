/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract AB_Greeter {
  string greeting;
  address multisigA;
  address multisigB;

  bytes32 proposedGreetingA = 0;
  bytes32 proposedGreetingB = 0;  


  constructor(string memory _greeting, 
              address _multisigA, 
              address _multisigB) {
    greeting = _greeting;
    multisigA = _multisigA;
    multisigB = _multisigB;
  }

  function greet() public view returns (string memory) {
    return greeting;
  }

  function setGreeting(string memory _greeting) internal {
    greeting = _greeting;
  }

  function proposeGreetingA(string calldata _greeting) public {
    require(msg.sender == multisigA, "Only for use by multisig A");
    bytes32 _hashedProposal = keccak256(abi.encode(_greeting));

    if(_hashedProposal == proposedGreetingB)
      setGreeting(_greeting);
    else
      proposedGreetingA = _hashedProposal;
  }

  function changeMultisigA(address _newMultiA) public {
    require(msg.sender == multisigA, "Only for use by multisig A");    
    multisigA = _newMultiA;
  }

 function proposeGreetingB(string calldata _greeting) public {
    require(msg.sender == multisigB, "Only for use by multisig B");
    bytes32 _hashedProposal = keccak256(abi.encode(_greeting));

    if(_hashedProposal == proposedGreetingA)
      setGreeting(_greeting);
    else
      proposedGreetingB = _hashedProposal;
    
  }

  function changeMultisigB(address _newMultiB) public {
    require(msg.sender == multisigB, "Only for use by multisig B");    
    multisigB = _newMultiB;
  }

}