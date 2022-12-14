// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract SimpleContract {
    uint256 public constructorValue;
    uint256 public contractBalance;
    uint256 public someAmount;
    uint16 private _someValue1;
    address private _owner;
    uint32 private _someValue2;
    bool private _someBool;
    string private _someString;

    constructor(uint256 constructorValue_) {
        constructorValue = constructorValue_;
        _owner = msg.sender;
    }

    function setOtherValues(
        uint16 someValue1_,
        uint32 someValue2_,
        bool someBool_,
        string memory someString_
    ) public {
        _someValue1 = someValue1_;
        _someValue2 = someValue2_;
        _someBool = someBool_;
        _someString = someString_;
    }

    function deposit() public payable {
        contractBalance += msg.value;
    }

    function withdraw(uint256 amount) public {
        payable(msg.sender).transfer(amount);
        contractBalance -= amount;
    }

    function setNewValue(uint256 newValue_) public returns (uint256) {
        someAmount += newValue_;
        return someAmount;
    }
}