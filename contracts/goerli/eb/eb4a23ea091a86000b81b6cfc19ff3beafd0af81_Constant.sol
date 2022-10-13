// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../interfaces/IEmissionCurve.sol";

contract Constant is IEmissionCurve{
    function getRate(uint lastRewardTime) external pure override returns (uint rate) {
        rate = 1e17;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IEmissionCurve {
    function getRate(uint lastRewardTime) external view returns (uint rate);
}