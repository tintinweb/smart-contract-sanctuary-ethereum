// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    function fetchPrice() external view returns (bool, uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IOracle } from "../interfaces/IOracle.sol";

contract StubOracle is IOracle {
    uint public price;

    function setPrice(uint _price) external {
        price = _price;
    }

    function fetchPrice() external view override returns (bool, uint) {
        return (true, price);
    }
}