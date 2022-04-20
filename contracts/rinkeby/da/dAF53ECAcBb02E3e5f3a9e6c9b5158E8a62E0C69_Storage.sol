// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Storage {
    uint256 internal _data;

    event DataStored(uint256 data, address user);

    function storeWithEvent(uint256 data) public {
        _data = data;
        emit DataStored(data, msg.sender);
    }

    function store(uint256 data) public {
        _data = data;
    }

    function getData() public view returns (uint256 data) {
        data = _data;
    }
}