// SDPX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract AddxFunding{
    event UpdatedAmount(string oldAmt, string newAmt);

    string public amount;

    constructor (string memory initAmount) {
        amount = initAmount;
    }

    function update(string memory newAmount) public {
        string memory oldAmt = amount;
        amount = newAmount;
        emit UpdatedAmount(oldAmt, newAmount);    
    }
}