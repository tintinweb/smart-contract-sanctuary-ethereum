// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

// interface IUniswapV3TickSpacing {
//     function tickSpacing() external view returns (int24);
// }

// contract L2_PolygonMessengerProxy {
//     function testTickSpacing(address pool) public returns (int24) {
//         return IUniswapV3TickSpacing(pool).tickSpacing();
//     }
// }


contract L2_PolygonMessengerProxy {
   function sendCrossDomainMessage(string memory signature) external pure returns (bytes memory) 
    {
        //  "setAmmWrapper(address)", "0x8ed4Cda3195C24F6F1E2b9784c6787b247CCFecE"
        bytes memory message = abi.encodeWithSignature(signature);
        return message;
    }
}