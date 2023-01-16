// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IEchoer } from "./IEchoer.sol";

contract Hello is IEchoer {
    function echo() external pure returns (string memory) {
        return "Hello, ";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IEchoer {
    function echo() external pure returns (string memory);
}