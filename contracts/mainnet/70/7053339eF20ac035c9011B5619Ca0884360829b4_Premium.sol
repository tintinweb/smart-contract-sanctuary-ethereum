// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.9;

// Import this file to use console.log
import "./interfaces/IPremium.sol";

contract Premium is IPremium {
    uint16[100][24] private _premiumMesh;

    constructor(uint16[100][24] memory premiumMesh) {
        _premiumMesh = premiumMesh;
    }

    /**
    * @dev get premium by curveIdx and volatility.
    * @param curveIdx value 0-23.
    * @param vol value [0, 99000). 0 is 0%, 99000 is 990%.
    * @return the premium
    */
    function getPremium(uint256 curveIdx, uint256 vol) external view returns (uint256) {
        uint256 interval = 1000;
        uint256 volIdx = vol / interval;
        require(curveIdx < 24, "Index of Premium Curve exceeds limit");
        require(volIdx < 99, "Vol exceeds limit");
        return (
            uint256(_premiumMesh[curveIdx][volIdx]) * ((volIdx + 1) * interval - vol) + uint256(_premiumMesh[curveIdx][volIdx + 1]) * (vol - volIdx * interval)
        ) / interval;
    }

    /**
    * @return the precision of premium
    */
    function precision() external pure returns (uint256) {
        return 50000;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;


interface IPremium {
  function getPremium(uint256 curveIdx, uint256 vol) external view returns (uint256);
  function precision() external pure returns (uint256);
}