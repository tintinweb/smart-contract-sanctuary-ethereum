pragma solidity >=0.8.0;
//SPDX-License-Identifier: MIT
contract Storer {
    uint theInt;
    string theString;
    address moneyWaster;

    function setTheInt(uint anInt) external {
        theInt = anInt;
    }

    function setTheString(string calldata aString) external {
        theString = aString;
    }

    function wasteMoney() external payable {
        moneyWaster = msg.sender;
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}