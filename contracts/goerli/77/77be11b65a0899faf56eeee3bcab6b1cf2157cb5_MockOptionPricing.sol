// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IOptionPricing} from "contracts/interfaces/IOptionPricing.sol";

contract MockOptionPricing is IOptionPricing {
    uint256 internal price = 45000000;

    function setOptionPrice(uint256 _price) public {
        price = _price;
    }

    function getOptionPrice(
        bool,
        uint256,
        uint256,
        uint256,
        uint256
    ) external view returns (uint256) {
        return price;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IOptionPricing {
    function getOptionPrice(
        bool isPut,
        uint256 expiry,
        uint256 strike,
        uint256 lastPrice,
        uint256 baseIv
    ) external view returns (uint256);
}