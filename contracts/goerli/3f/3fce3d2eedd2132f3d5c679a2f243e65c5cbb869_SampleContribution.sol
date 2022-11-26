//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IContribution {
    function getContribution(address member) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IContribution} from "./IContribution.sol";

contract SampleContribution is IContribution {
    mapping(address => uint256) public contributions;

    function addContribution(address member, uint256 contribute) external {
        contributions[member] = contribute;
    }

    function getContribution(address member) external view returns (uint256) {
        return contributions[member];
    }
}