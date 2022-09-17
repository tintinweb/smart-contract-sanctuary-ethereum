// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Parent } from "./stuff/Parent.sol";

contract ContractAE is Parent {
    constructor(string memory _name) {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Parent {}