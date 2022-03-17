//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IChild {
    function mom() external view returns (address);
}

contract Mom {
    address public child;

    function born() public {
        child = address (new Child());
    }

    function getMom() public view returns (address) {
        return IChild(child).mom();
    }
}

contract Child {
    address public mom;

    constructor() {
        mom = msg.sender;
    }
}