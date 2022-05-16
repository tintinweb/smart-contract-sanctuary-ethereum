// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

contract EmergenceTester {
    struct Foo {
        string barString;
        uint16 barsmallInt;
        uint256 barBigInt;
    }

    string public awesomeString;
    bool public awesomeBool;
    uint256 public awesomeInt;

    function payableFunction() external payable {
        require(msg.value == 100, "The value is incorrect");

        emit ReceivedFunds(msg.value);
    }

    function readUINT256() public view returns (uint256) {
        return address(this).balance;
    }

    function readStruct() public pure returns (Foo memory) {
        Foo memory bar = Foo("test", 1, 123123123123);
        return bar;
    }

    function readArray() public pure returns (string[2] memory) {
        return ["1", "two"];
    }

    function readArrayOfStructs() public pure returns (Foo[2] memory) {
        Foo memory bar = Foo("test", 1, 123123123123);
        Foo memory bar2 = Foo("test2", 2, 13241);

        return [bar, bar2];
    }

    function readBool() public pure returns (bool) {
        return true;
    }

    function readString() public view returns (string memory) {
        return awesomeString;
    }

    function setString(string memory _awesomeString) public returns (string memory) {
        awesomeString = _awesomeString;

        return awesomeString;
    }

    function setInt(uint256 _awesomeInt) public returns (uint256) {
        awesomeInt = _awesomeInt;

        return awesomeInt;
    }

    function setBool(bool _awesomeBool) public returns (bool) {
        awesomeBool = _awesomeBool;
        return awesomeBool;
    }

    function setMultipleParams(
        string memory _awesomeString,
        uint256 _awesomeInt,
        uint8 smallInt,
        bool _awesomeBool
    )
        public
        returns (
            uint256,
            string memory,
            bool,
            uint8
        )
    {
        awesomeBool = _awesomeBool;
        awesomeInt = _awesomeInt;
        awesomeString = _awesomeString;

        return (awesomeInt, awesomeString, awesomeBool, smallInt);
    }

    function setStruct(Foo memory bar) public pure returns (Foo memory) {
        return bar;
    }

    function setArray(Foo[] memory bars) public pure returns (Foo[] memory) {
        return bars;
    }

    function setBytes(bytes memory bars) public pure returns (bytes memory coolBytes) {
        return bars;
    }

    event ReceivedFunds(uint256 amount);
}