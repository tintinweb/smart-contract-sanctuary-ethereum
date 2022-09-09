// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract funoTypes {

    // Value Type Types
    // Initializing boolen variable
    // Making all Variable pucliy viewable in chain
    bool public fruit = true;

    // Initializing integar variable
    int24 public boulders = 5319009;

    // Initializing string variable
    string public str = "goblinTown.wtf";

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
    asphalt public WNV;

    // Create enum
    enum my_ethereum { ethereum_, _to, _ethereum }    
}