// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Store {
    event Log(string message);
    function log() public {
        emit Log("Store..");
    }
}

contract A {
    Store store;
    constructor(address _store) {
        store = Store(_store);
    }

    function callStore() public {
        store.log();
    }
}

contract Hack {
    event Log(string message);
    function log() public {
        emit Log("Hack..");
    }
}