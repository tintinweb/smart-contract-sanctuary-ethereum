// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint public favoriteNumber;

    //宣告一個event名為storedNumber,其中有四個參數
    event storedNumber(
        uint indexed oldNumber,
        uint indexed newNumber,
        uint addedNumber,
        address sender
    );

    function store(uint _number) public {
        //觸發event,把要輸出的值放進去,順序會對應event的宣告順序
        emit storedNumber(
            favoriteNumber, //oldNumber
            _number, //newNumber
            favoriteNumber + _number, //addedNumber
            msg.sender //sender
        );
        favoriteNumber = _number;
    }
}