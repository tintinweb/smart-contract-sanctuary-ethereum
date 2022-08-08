// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "../IFarm.sol";


contract FarmBase is IFarm {

    struct Fraction{    
        uint256 numerator;
        uint256 denominator;
    }

    Fraction public coefficent;
    uint256 public pctResourceTokenId;
    address public pctResourceAddress;
    string public pctResourceName;

    constructor(uint256 numerator, uint256 denominator, address resourceAddress, uint256 tokenId, string memory resourceName) {
        coefficent = Fraction(numerator, denominator);
        pctResourceTokenId = tokenId;
        pctResourceAddress = resourceAddress;
        pctResourceName = resourceName;
    }

    function estimateReward(uint256 amount, uint256 blocks) external view returns (uint256) {
        return amount * blocks * coefficent.numerator / coefficent.denominator;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IFarm {

    function estimateReward(uint256 amount, uint256 blocks) external view returns (uint256);
    
}