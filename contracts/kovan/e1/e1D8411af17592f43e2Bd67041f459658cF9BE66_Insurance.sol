// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IClaim.sol";

contract Insurance  {
    IClaim claim;
    constructor() public {}

    function Claim(address user) public view returns (uint256) {
        uint256 amout = claim.claim(user);

        return amout;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IClaim {
    function claim(address _owner) external view returns (uint256);
}