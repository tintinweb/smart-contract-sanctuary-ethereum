// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract IssueExample { 
    function test() external payable { 
        safeTransferETH(payable(0x1D23d55d6d4a33E000e24F2c0679b28609C5E3e3),msg.value); 
    } 

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }
}