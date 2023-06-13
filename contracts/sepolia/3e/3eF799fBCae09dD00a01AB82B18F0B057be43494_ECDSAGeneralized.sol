// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./EC.sol";

library ECDSAGeneralized {
    uint256 constant public n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function verify(uint256[12] memory params) public pure returns (bool) {
        uint256 u1 = mulmod(params[4], params[11], n);
        uint256 u2 = mulmod(params[5], params[11], n);
        require(EC.ecmulVerify(params[0], params[1], u1, params[7], params[8]));
        require(EC.ecmulVerify(params[2], params[3], u2, params[9], params[10]));

        (uint256 Qx, uint256 Qy) = EC.ecAdd(params[7], params[8], params[9], params[10]);

        return (Qx == params[5] && Qy == Qy);
    }
}