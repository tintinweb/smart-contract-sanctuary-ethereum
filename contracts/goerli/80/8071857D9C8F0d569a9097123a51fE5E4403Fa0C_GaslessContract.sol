//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract GaslessContract {
    function doOperationPayback() external {
        uint256 gasStart = gasleft();
        uint256 temp = 0;
        for(uint i = 0; i < 100; i++) {
            temp += i;
        }

        uint256 gasEnd = gasleft();
        uint256 gasUsed = gasStart - gasEnd + 31000;
        uint256 gasCost = gasUsed * tx.gasprice;

        payable(msg.sender).transfer(gasCost);
    }
}