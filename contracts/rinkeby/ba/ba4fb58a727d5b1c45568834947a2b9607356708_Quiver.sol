// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IQuiver} from "./interfaces/IQuiver.sol";
import {ETHArrow, ERC20Arrow, ERC721Arrow} from "./Arrows.sol";
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


    constructor() {
        // setup 3 basic Arrow types
        _set(bytes32("ethArrow"), type(ETHArrow).creationCode);
        _set(bytes32("erc20Arrow"), type(ERC20Arrow).creationCode);
        _set(bytes32("erc721Arrow"), type(ERC721Arrow).creationCode);

    }

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

    /// The inernal setter for arrows -- used in the constructor.
    /// @param arrowId Id of arrow in bytes.  Example: "sendEth"
    /// @param creationCode The creation code for the Arrow. Obtainable with: type(ArrowContract).creationCode
    /// @dev This will overwrite any existing value.  Use with caution.
    function _set(bytes32 arrowId, bytes memory creationCode) internal {
        arrows[arrowId] = creationCode;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IQuiver {
    function draw(bytes32 arrowId) external view returns (bytes memory);

    function set(bytes32 arrowId, bytes calldata creationCode) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;



interface IERC20 {

    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

/// This arrow transfers eth and self destructs.
contract ETHArrow {
    constructor(address payable misterX) {
        selfdestruct(misterX);
    }
}

/// This arrow transfers the balance of one ERC20 token, then self destructs. From selfdestruct, it also sends all eth.
contract ERC20Arrow {
    constructor(address payable misterX, IERC20 token ) {
        token.transfer(misterX, token.balanceOf(address(this)));
        selfdestruct(misterX);
    }
}

/// This arrow transfers one ERC721 token and self destructs.  When selfdestructing it also sends all eth.
contract ERC721Arrow {
    constructor(address payable misterX, IERC721 token, uint256 tokenId) {
        token.transferFrom(address(this), misterX, tokenId);
        selfdestruct(misterX);
    }
}


/// This arrow transfers one ERC721 nft and self destructs.