pragma solidity ^0.8.0;

contract Test {

    bytes32 public test;
    bytes32 public test2;
    bytes32 public test3;
    bytes public btest;
    uint len;

    constructor() {

    }

    function stringToBytes32(string memory source) public returns (bytes32) {
        bytes memory tempEmptyStringTest = bytes(source);
        btest = tempEmptyStringTest;
        bytes32 aa;
        bytes32 bb;
        bytes32 cc;
        // if (tempEmptyStringTest.length == 0) {
        //     return 0x0;
        // }

        assembly {
            aa := mload(add(source, 32))
            bb := mload(add(source, 64))
            cc := mload(add(source, 128))
        }
        test = aa;
        test2 = bb;
        test3 = cc;
    }
}