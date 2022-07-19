// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TPDIDForwardPolicies {
    address private _swapManager;

    constructor(address swapManager_) {
        _swapManager = swapManager_;
    }

    function swapManager() public view returns (address) {
        return _swapManager;
    }

    function forwardCheckOwner(
        address destination,
        bytes memory data,
        uint value
    ) public view returns (bool) {
        (data);
        (value);
        return destination == _swapManager;
    }
}