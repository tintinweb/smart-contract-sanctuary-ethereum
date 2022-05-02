// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IQuiver} from "./interfaces/IQuiver.sol";
/*

              .. ^
           ^ /|\\|\
          /|\ || |
           |  || |
           |  || |
           |  || |
        -'"|  ||"|-.
      (    |  || |  )
      |`-..|.___..-'|
      |             |
     /|             |
    / |             |
    |/|            '|
    | |            .|
    | |            '/
    | |            /|   ,ad8888ba,    88        88  88  8b           d8  88888888888  88888888ba
    | |           ' |  d8"'    `"8b   88        88  88  `8b         d8'  88           88      "8b
    | |           / | d8'        `8b  88        88  88   `8b       d8'   88           88      ,8P
    |\|          '..| 88          88  88        88  88    `8b     d8'    88aaaaa      88aaaaaa8P'
     \| if found    | 88          88  88        88  88     `8b   d8'     88"""""      88""""88'
      | return to   | Y8,    "88,,8P  88        88  88      `8b d8'      88           88    `8b
      \   HUNTER    /  Y8a.    Y88P   Y8a.    .a8P  88       `888'       88           88     `8b
       `-.._____ .-'    `"Y8888Y"Y8a   `"Y8888Y"'   88        `8'        88888888888  88      `8b

*/

/// The Quiver holds the Arrows that the Hunter shoots.
/// @title Quiver.sol
/// @author @devtooligan
/// @dev CloudHunter is a system for pre-computing, managing and deploying lazy, counterfactual, wallet contracts.
/// Arrows are a contract's creationCode. They are used for pre-computing create2 addresses and deploying to the address.
contract Quiver is IQuiver {
    /// The internal registry that tracks the Arrows' creation codes.
    mapping(bytes32 => bytes) internal arrows;

    /// The external getter for Arrows.
    /// @param arrowId Id of arrow in bytes.  Example: "sendEth"
    /// @return The creation code for the Arrow.
    function draw(bytes32 arrowId) external view returns (bytes memory) {
        return arrows[arrowId];
    }

    /// The external setter for arrows.
    /// @param arrowId Id of arrow in bytes.  Example: "sendEth"
    /// @param creationCode The creation code for the Arrow. Obtainable with: type(ArrowContract).creationCode
    /// @return True if successful.
    /// @dev This will overwrite any existing value.  Use with caution.
    function set(bytes32 arrowId, bytes calldata creationCode) external returns (bool) {
        arrows[arrowId] = creationCode;
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IQuiver {
    function draw(bytes32 arrowId) external view returns (bytes memory);

    function set(bytes32 arrowId, bytes calldata creationCode) external returns (bool);
}