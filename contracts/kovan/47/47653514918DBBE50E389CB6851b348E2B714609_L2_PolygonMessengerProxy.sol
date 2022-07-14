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
        bytes memory message = abi.encodeWithSignature("setAmmWrapper(address)", "0x045a19A74097caCC5C1f0BB13783Bc4e89e38B1A");
        emit NewMessage(message);
        return message;
    }
}