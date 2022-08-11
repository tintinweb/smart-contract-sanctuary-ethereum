// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

import "./Logic.sol";

contract DelegateCall {
    address public owner;
    Logic public logic;

    constructor (address _logic) public{
        logic = Logic(_logic);
        owner = msg.sender;                         // Announces deployer as the owner.
    }

    fallback() external payable{
        address(logic).delegatecall(msg.data);      // Delegates the call to Logic contract.
    }
}

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

contract Logic {
   address public owner;

   function changeOwner() public {
    owner = msg.sender;                 // Re-announce ownership but performed in a delegate call opcode so preserves the context and changes calling contract state variable.
   }
}