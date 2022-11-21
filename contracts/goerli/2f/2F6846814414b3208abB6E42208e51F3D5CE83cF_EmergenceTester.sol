// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

contract EmergenceTester {
    struct Foo {
        string barString;
        uint16 barsmallInt;
        uint256 barBigInt;
        bytes4 smallBytes;
        bool boolean;
    }

    struct Foo2 {
        string barString;
        bool boolean;
        FooChild bar1;
        FooChild bar2;
    }

    struct FooChild {
        bool boolean;
        bytes4 smallBytes;
        FooGrandChild grandson;
    }

    struct FooGrandChild {
        uint16 smallInt;
    }

    string public awesomeString;
    bool public awesomeBool;
    uint256 public awesomeInt;

    bytes4 public awesomeBytes;

    function payableFunction() external payable {
        require(msg.value == 100, "The value is incorrect");

        emit ReceivedFunds(msg.value);
    }

    function readInt(int256 test) public pure returns (int256) {
        return test;
    }

    function readBytes(bytes4 test) public pure returns (bytes4) {
        return test;
    }

    function readStruct(Foo memory test) public pure returns (Foo memory) {
        return test;
    }

    function readBool(bool test) public pure returns (bool) {
        return test;
    }

    function readMultipleTypes(
        string memory test1,
        uint128 test2,
        bool test3,
        bytes4 test4
    )
        public
        pure
        returns (
            string memory,
            uint128,
            bool,
            bytes4
        )
    {
        return (test1, test2, test3, test4);
    }

    function readMultipleTypes2(
        Foo memory test1,
        string memory test2,
        bool test3,
        bytes16 test4
    )
        public
        pure
        returns (
            Foo memory,
            string memory,
            bool,
            bytes16
        )
    {
        return (test1, test2, test3, test4);
    }

    function readMultipleTypes3(Foo2 memory test1, string memory test2)
        public
        pure
        returns (Foo2 memory, string memory)
    {
        return (test1, test2);
    }

    event ReceivedFunds(uint256 amount);
}