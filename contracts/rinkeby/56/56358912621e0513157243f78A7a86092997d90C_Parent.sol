pragma solidity ^0.8.0;

import "./Child.sol";

contract Parent {

Child public child;
    constructor(address a) {
        child = new Child(a);
    }
}

pragma solidity ^0.8.0;

contract Child {

    address public a;
    constructor(address _a) {
        a = _a;
    }

    function setAddress(address s) public {
        a = s;
    }
}