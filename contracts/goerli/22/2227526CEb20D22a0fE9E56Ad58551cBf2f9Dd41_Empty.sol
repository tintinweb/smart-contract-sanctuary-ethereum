// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Empty {
    struct Example {
        bool a;
        uint b;
        uint c;
    }

    mapping(uint => Example) setMe;

    function setIt(Example calldata x) public {
        setMe[1] = x;
    }
}