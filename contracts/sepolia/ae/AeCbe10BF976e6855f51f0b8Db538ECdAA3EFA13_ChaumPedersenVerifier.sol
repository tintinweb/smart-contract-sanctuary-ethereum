// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./EC.sol";

library ChaumPedersenVerifier {
    function verifyChaumPedersen(uint256[22] memory params) public pure returns (bool) {
        uint256[12] memory params1 = [
            params[0],
            params[1],
            params[2],
            params[3],
            params[9],
            params[10],
            params[8],
            params[13],
            params[14],
            params[15],
            params[16],
            params[17]
        ];
        bool b1 = verifyChaumPedersenSub(params1);
        
        uint256[12] memory params2 = [
            params[4],
            params[5],
            params[6],
            params[7],
            params[11],
            params[12],
            params[8],
            params[13],
            params[18],
            params[19],
            params[20],
            params[21]
        ];
        bool b2 = verifyChaumPedersenSub(params2);

        return b1 && b2;
    }

    function verifyChaumPedersenSub(uint256[12] memory params) internal pure returns (bool) {
        require(EC.ecmulVerify(params[0], params[1], params[7], params[8], params[9]));
        require(EC.ecmulVerify(params[2], params[3], params[6], params[10], params[11]));

        (uint256 sCy2x, uint256 sCy2y) = EC.ecAdd(params[10], params[11], params[4], params[5]);

        return (params[8] == sCy2x) && (params[9] == sCy2y);
    }
}