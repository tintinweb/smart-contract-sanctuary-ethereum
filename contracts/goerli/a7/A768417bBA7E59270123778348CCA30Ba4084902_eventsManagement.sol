//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract eventsManagement{
    uint256 public favoriteNumber;
    event storeNumber(
        uint indexed oldNumber,
        uint indexed newNumber,
        uint addeedNumber,
        address sender
    );



    function store(uint _newFavoriteNumber)public{
        emit storeNumber(
            favoriteNumber,
            _newFavoriteNumber,
            favoriteNumber + _newFavoriteNumber,
            msg.sender
        );
        favoriteNumber = _newFavoriteNumber;
    }

}