// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract Store {
    event log(string message) ;
    function deposit() public {
        emit log("store ...") ;
    }
}

contract A {
    Store store ;
    constructor (address _store) {
        store = Store(_store);
    }
    function callStore() public {
        store.deposit();
    }

}