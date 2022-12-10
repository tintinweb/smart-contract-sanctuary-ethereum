// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

// AI Inu is an ERC20 token that is updatable and transferable <3
contract AIInu is ERC20, Ownable {
    // The current vaweshon of the AI Inu contract
    string public vaweshon;

    // The address of the contract that is currently in control of the AI Inu contract
    address public contwawoller;

    constructor() ERC20("AI INU", "AIINU") {
        // Initialize the vaweshon and contwawoller
        vaweshon = "1.0";
        contwawoller = msg.sender;
    }

    // Upgrade the AI Inu contract to a new vaweshon
    function updwate(string memory _vaweshon) public {
        // Only the contwawoller can updwate the contract
        require(msg.sender == contwawoller, "Only the contwawoller can updwate the contract");

        // Set the new vaweshon
        vaweshon = _vaweshon;
    }

    // Transfer ownership of the AI Inu contract
    function twansferOwnewship(address newOwwner) public {
        // Only the current owwner can twansfer ownership
        require(msg.sender == owner(), "Only the current owwner can twansfer ownership");

        // Twansfer ownership to the new owwner
        contwawoller = newOwwner;
    }
}