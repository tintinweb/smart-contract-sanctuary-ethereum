// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.9.0;
import "./IZenLibrary.sol";

contract ZenTest {
    IZenLibrary lib;

    constructor() {
        lib = IZenLibrary(address(0x720E70557b0a075F5dC5811EC7A259e7cBDF4F5C));
    }

    function test() external view returns (string memory) {
        return lib.getLibrary();
    }
}

interface IZenLibrary {
    function getLibrary() external view returns (string memory);
}