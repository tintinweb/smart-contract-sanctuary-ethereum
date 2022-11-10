// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

// Import this file to use console.log
import "./interfaces/IPremium.sol";

contract Premium is IPremium {
    uint16[100][24] private _premiumMesh;

    constructor(uint16[100][24] memory premiumMesh) {
        _premiumMesh = premiumMesh;
    }

    function getPremium(uint256 curveIdx, uint256 vol) external view returns (uint256) {
        require(curveIdx < 24, "Index of Premium Curve exceeds limit");
        uint256 volIdx = vol / 500;
        require(volIdx < 99, "Vol exceeds limit");
        return (uint256(_premiumMesh[curveIdx][volIdx]) * ((volIdx + 1) * 500 - vol) + uint256(_premiumMesh[curveIdx][volIdx + 1]) * (vol - volIdx * 500)) / 500;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;


interface IPremium {
  function getPremium(uint256 curveIdx, uint256 vol) external view returns (uint256);
}