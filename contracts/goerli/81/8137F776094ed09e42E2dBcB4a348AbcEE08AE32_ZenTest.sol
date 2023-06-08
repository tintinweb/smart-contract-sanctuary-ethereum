// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.9.0;
import "./IZenLibrary.sol";

contract ZenTest {

    constructor() {
    }

    function test() external view returns (string memory) {
        return IZenLibrary(address(0xC5587bb17bC17Ee1Ff5e4cea28d177CA5f8d71D3)).exec();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.2 <0.9.0;

interface IZenLibrary {
    // It doesn't matter what this function is named. The constructor
    // will always be called.
    function exec() external view returns (string memory);
}