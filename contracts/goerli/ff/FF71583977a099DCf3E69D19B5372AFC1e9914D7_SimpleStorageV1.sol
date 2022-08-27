// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

contract SimpleStorageV1 {
    uint256 favoriteNumber;
    bool favoriteBool;

    // Emitted when the stored value changes
    event ValueChanged(uint256 newValue);

    function store(uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;
        emit ValueChanged(favoriteNumber);
    }

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }
}