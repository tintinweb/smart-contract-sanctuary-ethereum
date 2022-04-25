//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ChiToken {
        function freeFromUpTo(address from, uint256 value) external;
    }

contract Refund {

    ChiToken constant public chi = ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountCHI {
        uint256 gasStart = gasleft();

        _;

        uint256 initialGas = 21000 + 16 * msg.data.length;
        uint256 gasSpent = initialGas + gasStart - gasleft();
        uint256 freeUpValue = (gasSpent + 14154) / 41947;

        chi.freeFromUpTo(msg.sender, freeUpValue);
}

    function loop() public {
        for (uint i = 0; i < 50; i++) {}
    }

    function loopWithRefund () public discountCHI {
        for (uint i = 0; i < 50; i++) {}
    }
}