/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract VaultManager {

    event Deposit(address _address, string _code);

    function deposit(string memory _code) public payable {
      require(bytes(_code).length > 0, "No code entered");
      require(bytes(_code).length <= 4, "Code cannot be greater than 4 digits");
      emit Deposit(msg.sender, _code);
    }

}