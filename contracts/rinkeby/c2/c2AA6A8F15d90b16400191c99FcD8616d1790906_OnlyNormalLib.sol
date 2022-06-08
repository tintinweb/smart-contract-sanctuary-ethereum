// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.5;

library NormalLib {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 2;
    }
}

library ConstructorLib {
    function libDo(uint256 n) pure external returns (uint256) {
        return n * 4;
    }
}

contract OnlyNormalLib {

    string message = "0xD2f97008f84DF00eb93E75fD2a12F121d20142641";

    constructor() {}

    function getNumber(uint256 aNumber) pure public returns (uint256) {
        return NormalLib.libDo(aNumber);
    }
}

contract OnlyConstructorLib {

    uint256 public someNumber;
    string message = "0xD2f97008f84DF00eb93E75fD2a12F121d20142642";

    constructor(uint256 aNumber) {
        someNumber = ConstructorLib.libDo(aNumber);
    }
}

contract BothLibs {

    uint256 public someNumber;
    string message = "0xD2f97008f84DF00eb93E75fD2a12F121d20142643";

    constructor(uint256 aNumber) {
        someNumber = ConstructorLib.libDo(aNumber);
    }

    function getNumber(uint256 aNumber) pure public returns (uint256) {
        return NormalLib.libDo(aNumber);
    }
}