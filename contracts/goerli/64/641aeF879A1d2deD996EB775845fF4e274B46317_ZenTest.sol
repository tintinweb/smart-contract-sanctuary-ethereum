// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.9.0;
import "./IZenLibrary.sol";

contract ZenTest {

    constructor() {
    }

    function test() external view returns (string memory) {
        return IZenLibrary(address(0x55DC058eF9876c71bc0CF8E485861421b58A4e67)).getLibrary();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.9.0;

interface IZenLibrary {
    function getLibrary() external view returns (string memory);
}