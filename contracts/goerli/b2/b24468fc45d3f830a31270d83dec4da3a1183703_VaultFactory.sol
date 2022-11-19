/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract VaultFactory {
    mapping(address => Vault[]) public userVaults;

    function createVault(address owner) external {
        Vault vault = new Vault(owner);
        userVaults[owner].push(vault);
    }

    function createVaultWithPayment(address owner) external payable {
        Vault vault = new Vault{value: msg.value}(owner);
        userVaults[owner].push(vault);
    }
}

contract Vault {
   address public owner;
   uint public balance;

   constructor(address _owner) payable {
       owner = _owner;
       balance += msg.value;
   }

   fallback() external payable {
       balance += msg.value;
   }

   receive() external payable {
        balance += msg.value;
   }
   

   function deposit() external payable {
       balance += msg.value;
   }

   function withdraw(uint amount) external  {
       require(msg.sender == owner,"you are not authorized");
       balance -= amount;
       payable(owner).transfer(amount);


   }
}