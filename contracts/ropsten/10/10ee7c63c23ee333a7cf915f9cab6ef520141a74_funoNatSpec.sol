// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

    /// @title fun little Types contract
    /// @author Micah Gabbard
    /// @notice Just simple batch transfer with random type setting
    /// @dev https://github.com/micah4232


interface ERC721Partial {
    /// @notice the function doesn't return any value's
    /// @dev Micah Gabbard
    /// @custom:erc this function doesn't require @return or @inheritdoc because it is not public or event
    function transferFrom (address from, address to, uint256 tokenId) external;

}

contract funoNatSpec {

    // Value Type Types
    // Initializing boolen variable
    // Making all Variable pucliy viewable in chain
    bool public billBo = true;

    // Initializing integar variable
    int24 public boulders = 5319009;

    // Initializing string variable
    string public str = "frotoBaggin";

    // Initializing byte variable
    bytes public E;

    // Reference Type Types
    // Defining structure  
    struct asphalt {
        string material;
        string resin;
        string reflectors;
        uint8 panHandlers;
        bytes I;
        }

    // Define an array
    uint[3] public array = [uint(1), 2, 3 ];

    // Define structure object
    asphalt public schmegle;

    // Create enum
    enum my_precious { golem_, _to, _golem }    
}