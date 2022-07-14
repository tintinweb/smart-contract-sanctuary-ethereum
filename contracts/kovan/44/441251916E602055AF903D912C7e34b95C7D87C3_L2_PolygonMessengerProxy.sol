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

    event NewMessage(bytes data);

    function sendCrossDomainMessage() public returns (bytes memory) 
    {
        bytes memory message = abi.encodeWithSignature("setAmmWrapper(address)", "0x8488aB0c348bedE2555BfFfB6933F3BF7b263b20");
        emit NewMessage(message);
        return message;
    }
}