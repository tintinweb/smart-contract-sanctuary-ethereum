/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
contract StableCoin {
    // Mapping from address to balance
    mapping(address => uint256) public balances;

    // Event to track transfers
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Address of the contract owner
    address public owner;

    // The name of the stablecoin
    string public name = "CUSD";

    // The total supply of the stablecoin
    uint256 public totalSupply = 1000000000000;

    // The number of decimal places for the stablecoin
    uint8 public decimalPlaces = 18;

    // Function to add the used contract address
    function addContractAddress(address _usedContract) public {
    }

        // Function to transfer tokens
    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value);
        emit Transfer(msg.sender, _to, _value);
    }
}