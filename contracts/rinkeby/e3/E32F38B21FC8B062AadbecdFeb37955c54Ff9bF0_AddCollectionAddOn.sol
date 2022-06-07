// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract AddCollectionAddOn {
    event AddCollection(address add_);
    mapping(address => bool) public addressAdded;

    function addCollection(address add_) external returns(bool) {
        require(!addressAdded[add_]);
        addressAdded[add_] = true;
        emit AddCollection(add_);
        return true;
    }
}