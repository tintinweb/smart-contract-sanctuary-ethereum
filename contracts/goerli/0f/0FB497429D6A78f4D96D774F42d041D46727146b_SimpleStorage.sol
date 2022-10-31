// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "hardhat/console.log";

contract SimpleStorage {
    uint256 desiredHeight;

    // Adding the virtual keyword for functions we'd like to be overriden
    function addDesire(uint256 desire) public virtual {
        desiredHeight = desire;
    }

    function whatIDesire() public view returns (uint256) {
        return desiredHeight;
    }

    struct People {
        string name;
        uint256 height;
    }

    // Mappings are pretty much like dictionaries
    mapping(string => uint256) public nameToHeight;

    People[] public girls;

    // Structs, mappings and arrays need to be given memory or calldata when used as function arguments
    function add(string memory name, uint256 height) public {
        girls.push(People(name, height));
        nameToHeight[name] = height;
    }
    // When actually deployed on the blockchain, the functions which spend gas to execute will trigger your wallet everytime you've ran them manually.

    // The compiled code comes down to the EVM, which is little more than a standard to what a code gets reduced.
    // Some other EVM compatible blockchaines are Avalanche, Phanton, Polygon
}