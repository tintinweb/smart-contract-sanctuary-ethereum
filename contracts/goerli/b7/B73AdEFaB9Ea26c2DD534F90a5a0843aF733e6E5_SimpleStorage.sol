//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract SimpleStorage {
    uint256 private favNum;

    event infoAbout(
        uint256 indexed startedValue,
        uint256 indexed newValue,
        uint256 sum,
        address sender
    );

    function store(uint256 _favNum) public {
        emit infoAbout(favNum, _favNum, favNum + _favNum, msg.sender);
        favNum = _favNum;
    }

    function retrieve() public view returns (uint256) {
        return favNum;
    }
}