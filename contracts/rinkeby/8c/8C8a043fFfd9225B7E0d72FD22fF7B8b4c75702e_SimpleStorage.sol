// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract SimpleStorage {

    string public name; // default in storage

    // stores a name in the storage
    // string is not primitive, it needs to be referenced, this is why we add memory descriptor
    // it is a convention to name private identifiers with underscore
    function store(string memory _name) public virtual {
        name = _name;
    }
}