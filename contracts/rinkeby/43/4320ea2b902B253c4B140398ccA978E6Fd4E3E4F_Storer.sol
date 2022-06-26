pragma solidity >=0.8.0;
//SPDX-License-Identifier: MIT
contract Storer {
    uint public theInt;
    string public theString;
    address public moneyWaster;

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