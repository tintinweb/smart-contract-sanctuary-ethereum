pragma solidity 0.8.9;


contract Template {
    address immutable public creator;

    constructor() {
        creator = msg.sender;
    }

}