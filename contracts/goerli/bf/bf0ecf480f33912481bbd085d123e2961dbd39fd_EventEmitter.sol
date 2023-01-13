/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

contract EventEmitter {
    // Define the owner of the contract
    address public owner;

    // Define a mapping to store the authorization status of each address for each identifier
    mapping(address => mapping(string => bool)) public isAuthorized;

    // Define the event that will be emitted when the function is called
    event LogArgument(address indexed sender, string indexed identifier, bytes message, uint256 value);

    constructor() {
        // Set the contract owner to the address that deployed the contract
        owner = msg.sender;
    }

    // Define the function that will emit the event
    function emitEvent(string memory identifier, bytes memory message, uint256 value) public {
        // Only allow authorized addresses to call this function
        require(isAuthorized[msg.sender][identifier], "Unauthorized address");

        // Emit the event with the message sender, identifier, and message passed into the function
        emit LogArgument(msg.sender, identifier, message, value);
    }

    // Define a function to authorize an address for a specific identifier
    function authorize(string memory identifier, address addr) public {
        // Only allow the owner to authorize addresses
        require(msg.sender == owner, "Only the owner can authorize addresses");

        // Set the authorization status of the address for the given identifier to true
        isAuthorized[addr][identifier] = true;
    }

    // Define a function to remove authorization for an address for a specific identifier
    function removeAuthorization(string memory identifier, address addr) public {
        // Only allow the owner to remove authorization
        require(msg.sender == owner, "Only the owner can remove authorization");

        // Set the authorization status of the address for the given identifier to false
        isAuthorized[addr][identifier] = false;
    }

    // Define a function to transfer ownership of the contract
    function transferOwnership(address newOwner) public {
        // Only allow the owner to transfer ownership
        require(msg.sender == owner, "Only the owner can transfer ownership");

        // Transfer ownership to the new owner
        owner = newOwner;
    }
}